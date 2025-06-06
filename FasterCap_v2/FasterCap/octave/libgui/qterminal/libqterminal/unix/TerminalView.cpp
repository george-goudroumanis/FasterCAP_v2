/*
    This file is part of Konsole, a terminal emulator for KDE.

    Copyright (C) 2006-7 by Robert Knight <robertknight@gmail.com>
    Copyright (C) 1997,1998 by Lars Doelle <lars.doelle@on-line.de>

    Rewritten for QT4 by e_k <e_k at users.sourceforge.net>, Copyright (C)2008
    Copyright (C) 2012-2019 Jacob Dawid <jacob.dawid@cybercatalyst.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
    02110-1301  USA.
*/

#if defined (HAVE_CONFIG_H)
#  include "config.h"
#endif

#include "qt-utils.h"

// Own
#include "unix/TerminalView.h"

// Qt
#include <QApplication>
#include <QBoxLayout>
#include <QClipboard>
#include <QKeyEvent>
#include <QtCore/QEvent>
#include <QtCore/QTime>
#include <QtCore/QFile>
#include <QGridLayout>
#include <QLabel>
#include <QLayout>
#include <QPainter>
#include <QPixmap>
#include <QScrollBar>
#include <QStyle>
#include <QToolTip>
#include <QtCore>
#include <QtGui>

#include "unix/Filter.h"
#include "unix/konsole_wcwidth.h"
#include "unix/ScreenWindow.h"
#include "unix/TerminalCharacterDecoder.h"

#include <signal.h>

#ifndef loc
#define loc(X,Y) ((Y)*_columns+(X))
#endif

#define yMouseScroll 1

#define REPCHAR   "ABCDEFGHIJKLMNOPQRSTUVWXYZ" \
  "abcdefgjijklmnopqrstuvwxyz" \
  "0123456789./+@"

// scroll increment used when dragging selection at top/bottom of window.

// static
bool TerminalView::_antialiasText = true;

/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                                Colors                                     */
/*                                                                           */
/* ------------------------------------------------------------------------- */

/* Note that we use ANSI color order (bgr), while IBMPC color order is (rgb)

   Code        0       1       2       3       4       5       6       7
   ----------- ------- ------- ------- ------- ------- ------- ------- -------
   ANSI  (bgr) Black   Red     Green   Yellow  Blue    Magenta Cyan    White
   IBMPC (rgb) Black   Blue    Green   Cyan    Red     Magenta Yellow  White
*/

ScreenWindow* TerminalView::screenWindow() const
{
  return _screenWindow;
}
void TerminalView::setScreenWindow(ScreenWindow* window)
{
  // disconnect existing screen window if any
  if ( _screenWindow )
    {
      disconnect( _screenWindow , nullptr , this , nullptr );
    }

  _screenWindow = window;

  if ( window )
    {
      //#warning "The order here is not specified - does it matter whether updateImage or updateLineProperties comes first?"
      connect( _screenWindow , SIGNAL(outputChanged()) , this , SLOT(updateLineProperties()) );
      connect( _screenWindow , SIGNAL(outputChanged()) , this , SLOT(updateImage()) );
      window->setWindowLines(_lines);
    }
}

const ColorEntry* TerminalView::colorTable() const
{
  return _colorTable;
}

void TerminalView::setColorTable(const ColorEntry table[])
{
  for (int i = 0; i < TABLE_COLORS; i++)
    _colorTable[i] = table[i];

  QPalette p = palette();
  p.setColor( backgroundRole(), _colorTable[DEFAULT_BACK_COLOR].color );
  setPalette( p );

  // Avoid propagating the palette change to the scroll bar
  _scrollBar->setPalette( QApplication::palette() );

  update();
}

/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                                   Font                                    */
/*                                                                           */
/* ------------------------------------------------------------------------- */

/*
   The VT100 has 32 special graphical characters. The usual vt100 extended
   xterm fonts have these at 0x00..0x1f.

   QT's iso mapping leaves 0x00..0x7f without any changes. But the graphicals
   come in here as proper unicode characters.

   We treat non-iso10646 fonts as VT100 extended and do the required mapping
   from unicode to 0x00..0x1f. The remaining translation is then left to the
   QCodec.
*/

// assert for i in [0..31] : vt100extended(vt100_graphics[i]) == i.

unsigned short vt100_graphics[32] =
{ // 0/8     1/9    2/10    3/11    4/12    5/13    6/14    7/15
  0x0020, 0x25C6, 0x2592, 0x2409, 0x240c, 0x240d, 0x240a, 0x00b0,
  0x00b1, 0x2424, 0x240b, 0x2518, 0x2510, 0x250c, 0x2514, 0x253c,
  0xF800, 0xF801, 0x2500, 0xF803, 0xF804, 0x251c, 0x2524, 0x2534,
  0x252c, 0x2502, 0x2264, 0x2265, 0x03C0, 0x2260, 0x00A3, 0x00b7
};

void TerminalView::fontChange(const QFont&)
{
  QFontMetrics fm(font());
  _fontHeight = fm.height() + _lineSpacing;


  // waba TerminalDisplay 1.123:
  // "Base character width on widest ASCII character. This prevents too wide
  //  characters in the presence of double wide (e.g. Japanese) characters."
  // Get the width from representative normal width characters
  _fontWidth = ((double)octave::qt_fontmetrics_horizontal_advance(fm, REPCHAR)
                / (double)strlen(REPCHAR));

  _fixedFont = true;

  int fw = octave::qt_fontmetrics_horizontal_advance(fm, REPCHAR[0]);
  for(unsigned int i=1; i< strlen(REPCHAR); i++)
    {
      if (fw != octave::qt_fontmetrics_horizontal_advance(fm, REPCHAR[i]))
        {
          _fixedFont = false;
          break;
        }
    }


  if (_fontWidth < 1)
    _fontWidth = 1;

  _fontAscent = fm.ascent();

  emit changedFontMetricSignal( _fontHeight, _fontWidth );
  //parentWidget()->setFixedWidth(_fontWidth * 80 + _leftMargin);
  propagateSize();
  update();
}

void TerminalView::setVTFont(const QFont& f)
{
  QFont font = f;

  QFontMetrics metrics(font);

  if ( metrics.height() < height() && metrics.maxWidth() < width() )
    {
      // hint that text should be drawn without anti-aliasing.
      // depending on the user's font configuration, this may not be respected
      if (!_antialiasText)
        font.setStyleStrategy( QFont::NoAntialias );

      // experimental optimization.  Konsole assumes that the terminal is using a
      // mono-spaced font, in which case kerning information should have an effect.
      // Disabling kerning saves some computation when rendering text.
      // font.setKerning(false);

      int strategy = font.styleStrategy();
#if defined (HAVE_QFONT_FORCE_INTEGER_METRICS)
      strategy |= QFont::ForceIntegerMetrics;
#endif
      font.setStyleStrategy(QFont::StyleStrategy(strategy));

      QWidget::setFont(font);
      fontChange(font);
    }
}

void TerminalView::setFont(const QFont &)
{
  // ignore font change request if not coming from konsole itself
}

/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                         Constructor / Destructor                          */
/*                                                                           */
/* ------------------------------------------------------------------------- */

TerminalView::TerminalView(QWidget *parent)
  :QWidget(parent)
  ,_screenWindow(nullptr)
  ,_allowBell(true)
  ,_gridLayout(nullptr)
  ,_fontHeight(1)
  ,_fontWidth(1)
  ,_fontAscent(1)
  ,_lines(1)
  ,_columns(1)
  ,_usedLines(1)
  ,_usedColumns(1)
  ,_contentHeight(1)
  ,_contentWidth(1)
  ,_image(nullptr)
  ,_randomSeed(0)
  ,_resizing(false)
  ,_terminalSizeHint(false)
  ,_terminalSizeStartup(true)
  ,_disabledBracketedPasteMode(false)
  ,_actSel(0)
  ,_wordSelectionMode(false)
  ,_lineSelectionMode(false)
  ,_preserveLineBreaks(false)
  ,_columnSelectionMode(false)
  ,_scrollbarLocation(NoScrollBar)
  ,_wordCharacters(":@-./_~")
  ,_bellMode(SystemBeepBell)
  ,_blinking(false)
  ,_cursorBlinking(false)
  ,_hasBlinkingCursor(false)
  ,_ctrlDrag(false)
  ,_tripleClickMode(SelectWholeLine)
  ,_isFixedSize(false)
  ,_possibleTripleClick(false)
  ,_resizeWidget(nullptr)
  ,_resizeTimer(nullptr)
  ,_outputSuspendedLabel(nullptr)
  ,_lineSpacing(0)
  ,_colorsInverted(false)
  ,_blendColor(qRgba(0,0,0,0xff))
  ,_filterChain(new TerminalImageFilterChain())
  ,_cursorShape(BlockCursor)
  ,_readonly(false)
{
  // terminal applications are not designed with Right-To-Left in mind,
  // so the layout is forced to Left-To-Right
  setLayoutDirection(Qt::LeftToRight);

  // The offsets are not yet calculated.
  // Do not calculate these too often to be more smoothly when resizing
  // konsole in opaque mode.
  _topMargin = DEFAULT_TOP_MARGIN;
  _leftMargin = DEFAULT_LEFT_MARGIN;

  // create scroll bar for scrolling output up and down
  // set the scroll bar's slider to occupy the whole area of the scroll bar initially
  _scrollBar = new QScrollBar(this);
  setScroll(0,0);
  _scrollBar->setCursor( Qt::ArrowCursor );
  connect(_scrollBar, SIGNAL(valueChanged(int)), this,
          SLOT(scrollBarPositionChanged(int)));

  // setup timers for blinking cursor and text
  _blinkTimer   = new QTimer(this);
  connect(_blinkTimer, SIGNAL(timeout()), this, SLOT(blinkEvent()));

  _blinkCursorTimer   = new QTimer(this);
  connect(_blinkCursorTimer, SIGNAL(timeout()), this, SLOT(blinkCursorEvent()));

  _process_filter_timer = new QTimer (this);
  connect (_process_filter_timer, SIGNAL (timeout ()),
           this, SLOT (processFilters ()));
  _process_filter_timer->start (300);

  //  QCursor::setAutoHideCursor( this, true );

  setUsesMouse(true);
  setBracketedPasteMode(false);
  setColorTable(base_color_table);
  setMouseTracking(true);

  // Enable drag and drop
  setAcceptDrops(true); // attempt
  dragInfo.state = diNone;

  setFocusPolicy( Qt::WheelFocus );

  // enable input method support
  setAttribute(Qt::WA_InputMethodEnabled, true);

  // this is an important optimization, it tells Qt
  // that TerminalDisplay will handle repainting its entire area.
  setAttribute(Qt::WA_OpaquePaintEvent);

  _gridLayout = new QGridLayout(this);
  _gridLayout->setMargin(0);

  setLayout( _gridLayout );
}

TerminalView::~TerminalView()
{
  qApp->removeEventFilter( this );

  delete[] _image;

  delete _gridLayout;
  delete _outputSuspendedLabel;
  delete _filterChain;
}

/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                             Display Operations                            */
/*                                                                           */
/* ------------------------------------------------------------------------- */

/**
 A table for emulating the simple (single width) unicode drawing chars.
 It represents the 250x - 257x glyphs. If it's zero, we can't use it.
 if it's not, it's encoded as follows: imagine a 5x5 grid where the points are numbered
 0 to 24 left to top, top to bottom. Each point is represented by the corresponding bit.

 Then, the pixels basically have the following interpretation:
 _|||_
 -...-
 -...-
 -...-
 _|||_

where _ = none
      | = vertical line.
      - = horizontal line.
 */


enum LineEncode
{
  TopL  = (1<<1),
  TopC  = (1<<2),
  TopR  = (1<<3),

  LeftT = (1<<5),
  Int11 = (1<<6),
  Int12 = (1<<7),
  Int13 = (1<<8),
  RightT = (1<<9),

  LeftC = (1<<10),
  Int21 = (1<<11),
  Int22 = (1<<12),
  Int23 = (1<<13),
  RightC = (1<<14),

  LeftB = (1<<15),
  Int31 = (1<<16),
  Int32 = (1<<17),
  Int33 = (1<<18),
  RightB = (1<<19),

  BotL  = (1<<21),
  BotC  = (1<<22),
  BotR  = (1<<23)
};

void TerminalView::setKeyboardCursorShape(KeyboardCursorShape shape)
{
  _cursorShape = shape;
}
TerminalView::KeyboardCursorShape TerminalView::keyboardCursorShape() const
{
  return _cursorShape;
}
void TerminalView::setKeyboardCursorColor(bool useForegroundColor, const QColor& color)
{
  if (useForegroundColor)
    _cursorColor = QColor(); // an invalid color means that
  // the foreground color of the
  // current character should
  // be used

  else
    _cursorColor = color;
}
QColor TerminalView::keyboardCursorColor() const
{
  return _cursorColor;
}

void TerminalView::drawBackground(QPainter& painter, const QRect& rect, const QColor& backgroundColor)
{
  // the area of the widget showing the contents of the terminal display is drawn
  // using the background color from the color scheme set with setColorTable()
  //
  // the area of the widget behind the scroll-bar is drawn using the background
  // brush from the scroll-bar's palette, to give the effect of the scroll-bar
  // being outside of the terminal display and visual consistency with other KDE
  // applications.
  //
  QRect scrollBarArea = _scrollBar->isVisible() ?
        rect.intersected(_scrollBar->geometry()) :
        QRect();

  QRegion contentsRegion = QRegion(rect).subtracted(scrollBarArea);
  QRect contentsRect = contentsRegion.boundingRect();

  painter.fillRect(contentsRect, backgroundColor);
  painter.fillRect(scrollBarArea,_scrollBar->palette().window());
}

void TerminalView::drawCursor(QPainter& painter,
                              const QRect& rect,
                              const QColor& foregroundColor,
                              const QColor& /*backgroundColor*/,
                              bool& invertCharacterColor)
{
  QRect cursorRect = rect;
  cursorRect.setHeight(_fontHeight - _lineSpacing - 1);

  if (!_cursorBlinking)
    {
      if ( _cursorColor.isValid() )
        painter.setPen(_cursorColor);
      else {
          painter.setPen(foregroundColor);
        }

      if ( _cursorShape == BlockCursor )
        {
          // draw the cursor outline, adjusting the area so that
          // it is draw entirely inside 'rect'
          int penWidth = qMax(1,painter.pen().width());

          painter.drawRect(cursorRect.adjusted(penWidth/2,
                                               penWidth/2,
                                               - penWidth/2 - penWidth%2,
                                               - penWidth/2 - penWidth%2));
          if ( hasFocus() )
            {
              painter.fillRect(cursorRect, _cursorColor.isValid() ? _cursorColor : foregroundColor);

              if ( !_cursorColor.isValid() )
                {
                  // invert the colour used to draw the text to ensure that the character at
                  // the cursor position is readable
                  invertCharacterColor = true;
                }
            }
        }
      else if ( _cursorShape == UnderlineCursor )
        painter.drawLine(cursorRect.left(),
                         cursorRect.bottom(),
                         cursorRect.right(),
                         cursorRect.bottom());
      else if ( _cursorShape == IBeamCursor )
        painter.drawLine(cursorRect.left(),
                         cursorRect.top(),
                         cursorRect.left(),
                         cursorRect.bottom());

    }
}

void TerminalView::drawCharacters(QPainter& painter,
                                  const QRect& rect,
                                  const QString& text,
                                  const Character* style,
                                  bool invertCharacterColor)
{
  // don't draw text which is currently blinking
  if ( _blinking && (style->rendition & RE_BLINK) )
    return;

  // setup bold and underline
  bool useBold = style->rendition & RE_BOLD || style->isBold(_colorTable) || font().bold();
  bool useUnderline = style->rendition & RE_UNDERLINE || font().underline();

  QFont font = painter.font();
  if (    font.bold() != useBold
          || font.underline() != useUnderline )
    {
      font.setBold(useBold);
      font.setUnderline(useUnderline);
      painter.setFont(font);
    }

  const CharacterColor& textColor = ( invertCharacterColor ? style->backgroundColor : style->foregroundColor );
  const QColor color = textColor.color(_colorTable);

  QPen pen = painter.pen();
  if ( pen.color() != color )
    {
      pen.setColor(color);
      painter.setPen(color);
    }
  // draw text
  // the drawText(rect,flags,string) overload is used here with null flags
  // instead of drawText(rect,string) because the (rect,string) overload causes
  // the application's default layout direction to be used instead of
  // the widget-specific layout direction, which should always be
  // Qt::LeftToRight for this widget
  painter.drawText(rect,0,text);
}

void TerminalView::drawTextFragment(QPainter& painter ,
                                    const QRect& rect,
                                    const QString& text,
                                    const Character* style)
{
  painter.save();

  // setup painter
  const QColor foregroundColor = style->foregroundColor.color(_colorTable);
  const QColor backgroundColor = style->backgroundColor.color(_colorTable);

  // draw background if different from the display's background color
  if ( backgroundColor != palette().window().color() )
    drawBackground(painter,rect,backgroundColor);

  // draw cursor shape if the current character is the cursor
  // this may alter the foreground and background colors
  bool invertCharacterColor = false;

  if ( style->rendition & RE_CURSOR )
    drawCursor(painter,rect,foregroundColor,backgroundColor,invertCharacterColor);
  // draw text
  drawCharacters(painter,rect,text,style,invertCharacterColor);

  painter.restore();
}

void TerminalView::setRandomSeed(uint randomSeed) { _randomSeed = randomSeed; }
uint TerminalView::randomSeed() const { return _randomSeed; }

// scrolls the image by 'lines', down if lines > 0 or up otherwise.
//
// the terminal emulation keeps track of the scrolling of the character
// image as it receives input, and when the view is updated, it calls scrollImage()
// with the final scroll amount.  this improves performance because scrolling the
// display is much cheaper than re-rendering all the text for the
// part of the image which has moved up or down.
// Instead only new lines have to be drawn
//
// note:  it is important that the area of the display which is
// scrolled aligns properly with the character grid -
// which has a top left point at (_leftMargin,_topMargin) ,
// a cell width of _fontWidth and a cell height of _fontHeight).
void TerminalView::scrollImage(int lines , const QRect& screenWindowRegion)
{
  // if the flow control warning is enabled this will interfere with the
  // scrolling optimisations and cause artifacts.  the simple solution here
  // is to just disable the optimisation whilst it is visible
  if ( _outputSuspendedLabel && _outputSuspendedLabel->isVisible() ) {
      return;
    }

  // constrain the region to the display
  // the bottom of the region is capped to the number of lines in the display's
  // internal image - 2, so that the height of 'region' is strictly less
  // than the height of the internal image.
  QRect region = screenWindowRegion;
  region.setBottom( qMin(region.bottom(),this->_lines-2) );

  if (lines == 0
      || _image == nullptr
      || !region.isValid()
      || (region.top() + abs(lines)) >= region.bottom()
      || this->_lines <= region.height() )
    return;

  QRect scrollRect;

  void* firstCharPos = &_image[ region.top() * this->_columns ];
  void* lastCharPos = &_image[ (region.top() + abs(lines)) * this->_columns ];

  int top = _topMargin + (region.top() * _fontHeight);
  int linesToMove = region.height() - abs(lines);
  int bytesToMove = linesToMove *
      this->_columns *
      sizeof(Character);

  Q_ASSERT( linesToMove > 0 );
  Q_ASSERT( bytesToMove > 0 );

  //scroll internal image
  if ( lines > 0 )
    {
      // check that the memory areas that we are going to move are valid
      Q_ASSERT( (char*)lastCharPos + bytesToMove <
                (char*)(_image + (this->_lines * this->_columns)) );

      Q_ASSERT( (lines*this->_columns) < _imageSize );

      //scroll internal image down
      memmove( firstCharPos , lastCharPos , bytesToMove );

      //set region of display to scroll, making sure that
      //the region aligns correctly to the character grid
      scrollRect = QRect( _leftMargin , top,
                          this->_usedColumns * _fontWidth ,
                          linesToMove * _fontHeight );
    }
  else
    {
      // check that the memory areas that we are going to move are valid
      Q_ASSERT( (char*)firstCharPos + bytesToMove <
                (char*)(_image + (this->_lines * this->_columns)) );

      //scroll internal image up
      memmove( lastCharPos , firstCharPos , bytesToMove );

      //set region of the display to scroll, making sure that
      //the region aligns correctly to the character grid
      QPoint topPoint( _leftMargin , top + abs(lines)*_fontHeight );

      scrollRect = QRect( topPoint ,
                          QSize( this->_usedColumns*_fontWidth ,
                                 linesToMove * _fontHeight ));
    }

  //scroll the display vertically to match internal _image
  scroll( 0 , _fontHeight * (-lines) , scrollRect );
}

QRegion TerminalView::hotSpotRegion() const
{
  QRegion region;
  foreach( Filter::HotSpot* hotSpot , _filterChain->hotSpots() )
    {
      QRect rect;
      rect.setLeft(hotSpot->startColumn());
      rect.setTop(hotSpot->startLine());
      rect.setRight(hotSpot->endColumn());
      rect.setBottom(hotSpot->endLine());

      region |= imageToWidget(rect);
    }
  return region;
}

void TerminalView::processFilters()
{
  if (!_screenWindow)
    return;

  QRegion preUpdateHotSpots = hotSpotRegion();

  // use _screenWindow->getImage() here rather than _image because
  // other classes may call processFilters() when this display's
  // ScreenWindow emits a scrolled() signal - which will happen before
  // updateImage() is called on the display and therefore _image is
  // out of date at this point
  _filterChain->setImage( _screenWindow->getImage(),
                          _screenWindow->windowLines(),
                          _screenWindow->windowColumns(),
                          _screenWindow->getLineProperties() );
  _filterChain->process();

  QRegion postUpdateHotSpots = hotSpotRegion();

  update( preUpdateHotSpots | postUpdateHotSpots );
}

void TerminalView::updateImage()
{
  if ( !_screenWindow )
    return;
  updateLineProperties();

  // optimization - scroll the existing image where possible and
  // avoid expensive text drawing for parts of the image that
  // can simply be moved up or down
  scrollImage( _screenWindow->scrollCount() ,
               _screenWindow->scrollRegion() );
  _screenWindow->resetScrollCount();

  Character* const newimg = _screenWindow->getImage();
  int lines = _screenWindow->windowLines();
  int columns = _screenWindow->windowColumns();

  setScroll( _screenWindow->currentLine() , _screenWindow->lineCount() );

  if (!_image)
    updateImageSize(); // Create _image

  Q_ASSERT( this->_usedLines <= this->_lines );
  Q_ASSERT( this->_usedColumns <= this->_columns );

  int y,x,len;

  QPoint tL  = contentsRect().topLeft();

  int    tLx = tL.x();
  int    tLy = tL.y();
  _hasBlinker = false;

  CharacterColor cf;       // undefined
  CharacterColor _clipboard;       // undefined
  int cr  = -1;   // undefined

  const int linesToUpdate = qMin(this->_lines, qMax(0,lines  ));
  const int columnsToUpdate = qMin(this->_columns,qMax(0,columns));

  QChar *disstrU = new QChar[columnsToUpdate];
  char *dirtyMask = new char[columnsToUpdate+2];
  QRegion dirtyRegion;

  // debugging variable, this records the number of lines that are found to
  // be 'dirty' ( ie. have changed from the old _image to the new _image ) and
  // which therefore need to be repainted
  int dirtyLineCount = 0;

  for (y = 0; y < linesToUpdate; y++)
    {
      const Character*       currentLine = &_image[y*this->_columns];
      const Character* const newLine = &newimg[y*columns];

      bool updateLine = false;

      // The dirty mask indicates which characters need repainting. We also
      // mark surrounding neighbours dirty, in case the character exceeds
      // its cell boundaries
      memset(dirtyMask, 0, columnsToUpdate+2);

      for( x = 0 ; x < columnsToUpdate ; x++)
        {
          if ( newLine[x] != currentLine[x] )
            {
              dirtyMask[x] = true;
            }
        }

      if (!_resizing) // not while _resizing, we're expecting a paintEvent
        for (x = 0; x < columnsToUpdate; x++)
          {
            _hasBlinker |= (newLine[x].rendition & RE_BLINK);

            // Start drawing if this character or the next one differs.
            // We also take the next one into account to handle the situation
            // where characters exceed their cell width.
            if (dirtyMask[x])
              {
                quint16 c = newLine[x+0].character;
                if ( !c )
                  continue;
                int p = 0;
                disstrU[p++] = c; //fontMap(c);
                bool doubleWidth = (x+1 == columnsToUpdate) ? false : (newLine[x+1].character == 0);
                cr = newLine[x].rendition;
                _clipboard = newLine[x].backgroundColor;
                if (newLine[x].foregroundColor != cf) cf = newLine[x].foregroundColor;
                int lln = columnsToUpdate - x;
                for (len = 1; len < lln; len++)
                  {
                    const Character& ch = newLine[x+len];

                    if (!ch.character)
                      continue; // Skip trailing part of multi-col chars.

                    bool nextIsDoubleWidth = (x+len+1 == columnsToUpdate) ? false : (newLine[x+len+1].character == 0);

                    if (  ch.foregroundColor != cf ||
                          ch.backgroundColor != _clipboard ||
                          ch.rendition != cr ||
                          !dirtyMask[x+len] ||
                          nextIsDoubleWidth != doubleWidth )
                      break;

                    disstrU[p++] = c; //fontMap(c);
                  }

                QString unistr(disstrU, p);

                bool saveFixedFont = _fixedFont;
                if (doubleWidth)
                  _fixedFont = false;

                updateLine = true;

                _fixedFont = saveFixedFont;
                x += len - 1;
              }

          }

      //both the top and bottom halves of double height _lines must always be redrawn
      //although both top and bottom halves contain the same characters, only
      //the top one is actually
      //drawn.
      if (_lineProperties.count() > y)
        updateLine |= (_lineProperties[y] & LINE_DOUBLEHEIGHT);

      // if the characters on the line are different in the old and the new _image
      // then this line must be repainted.
      if (updateLine)
        {
          dirtyLineCount++;

          // add the area occupied by this line to the region which needs to be
          // repainted
          QRect dirtyRect = QRect( _leftMargin+tLx ,
                                   _topMargin+tLy+_fontHeight*y ,
                                   _fontWidth * columnsToUpdate ,
                                   _fontHeight );

          dirtyRegion |= dirtyRect;
        }

      // replace the line of characters in the old _image with the
      // current line of the new _image
      memcpy((void*)currentLine,(const void*)newLine,columnsToUpdate*sizeof(Character));
    }

  // if the new _image is smaller than the previous _image, then ensure that the area
  // outside the new _image is cleared
  if ( linesToUpdate < _usedLines )
    {
      dirtyRegion |= QRect(   _leftMargin+tLx ,
                              _topMargin+tLy+_fontHeight*linesToUpdate ,
                              _fontWidth * this->_columns ,
                              _fontHeight * (_usedLines-linesToUpdate) );
    }
  _usedLines = linesToUpdate;

  if ( columnsToUpdate < _usedColumns )
    {
      dirtyRegion |= QRect(   _leftMargin+tLx+columnsToUpdate*_fontWidth ,
                              _topMargin+tLy ,
                              _fontWidth * (_usedColumns-columnsToUpdate) ,
                              _fontHeight * this->_lines );
    }
  _usedColumns = columnsToUpdate;

  dirtyRegion |= _inputMethodData.previousPreeditRect;

  // update the parts of the display which have changed
  update(dirtyRegion);

  if ( _hasBlinker && !_blinkTimer->isActive()) _blinkTimer->start( BLINK_DELAY );
  if (!_hasBlinker && _blinkTimer->isActive()) { _blinkTimer->stop(); _blinking = false; }
  delete[] dirtyMask;
  delete[] disstrU;

}

void TerminalView::showResizeNotification()
{
  if (_terminalSizeHint && isVisible())
    {
      if (_terminalSizeStartup) {
          _terminalSizeStartup=false;
          return;
        }
      if (!_resizeWidget)
        {
          _resizeWidget = new QLabel(("Size: XXX x XXX"), this);
          _resizeWidget->setMinimumWidth(octave::qt_fontmetrics_horizontal_advance(_resizeWidget->fontMetrics(), "Size: XXX x XXX"));
          _resizeWidget->setMinimumHeight(_resizeWidget->sizeHint().height());
          _resizeWidget->setAlignment(Qt::AlignCenter);

          _resizeWidget->setStyleSheet("background-color:palette(window);border-style:solid;border-width:1px;border-color:palette(dark)");

          _resizeTimer = new QTimer(this);
          _resizeTimer->setSingleShot(true);
          connect(_resizeTimer, SIGNAL(timeout()), _resizeWidget, SLOT(hide()));

        }
      QString sizeStr = QString("Size: %1 x %2").arg(_columns).arg(_lines);
      _resizeWidget->setText(sizeStr);
      _resizeWidget->move((width()-_resizeWidget->width())/2,
                          (height()-_resizeWidget->height())/2+20);
      _resizeWidget->show();
      _resizeTimer->start(1000);
    }
}

void TerminalView::setBlinkingCursor(bool blink)
{
  _hasBlinkingCursor=blink;

  setBlinkingCursorState(blink);
}

void TerminalView::setBlinkingCursorState(bool blink)
{
  if (blink && !_blinkCursorTimer->isActive())
    _blinkCursorTimer->start(BLINK_DELAY);

  if (!blink && _blinkCursorTimer->isActive())
    {
      _blinkCursorTimer->stop();
      if (_cursorBlinking)
        blinkCursorEvent();
    }
}

void TerminalView::paintEvent( QPaintEvent* pe )
{
  updateImage();
  //qDebug("%s %d paintEvent", __FILE__, __LINE__);
  QPainter paint(this);
  //qDebug("%s %d paintEvent %d %d", __FILE__, __LINE__, paint.window().top(), paint.window().right());

#if defined (HAVE_QREGION_ITERATORS)
  for (QRect rect : (pe->region() & contentsRect()))
#else
  foreach (QRect rect, (pe->region() & contentsRect()).rects())
#endif
    {
      drawBackground(paint,rect,palette().window().color());
      drawContents(paint, rect);
    }
  //    drawBackground(paint,contentsRect(),palette().background().color(),	true /* use opacity setting */);
  //    drawContents(paint, contentsRect());
  drawInputMethodPreeditString(paint,preeditRect());
  paintFilters(paint);
  paint.end();
}

void TerminalView::focusInEvent(QFocusEvent *focusEvent)
{
  setBlinkingCursorState(true);
  updateImage();
  repaint();
  update();

  QWidget::focusInEvent(focusEvent);
}

void TerminalView::focusOutEvent(QFocusEvent *focusEvent)
{
  // Force the cursor to be redrawn.
  _cursorBlinking = true;
  setBlinkingCursorState(false);

  QWidget::focusOutEvent(focusEvent);
}

QPoint TerminalView::cursorPosition() const
{
  if (_screenWindow)
    return _screenWindow->cursorPosition();
  else
    return QPoint(0,0);
}

QRect TerminalView::preeditRect() const
{
  const int preeditLength = string_width(_inputMethodData.preeditString);

  if ( preeditLength == 0 )
    return QRect();

  return QRect(_leftMargin + _fontWidth*cursorPosition().x(),
               _topMargin + _fontHeight*cursorPosition().y(),
               _fontWidth*preeditLength,
               _fontHeight);
}

void TerminalView::drawInputMethodPreeditString(QPainter& painter , const QRect& rect)
{
  if ( _inputMethodData.preeditString.isEmpty() ) {
      return;
    }
  const QPoint cursorPos = cursorPosition();

  bool invertColors = false;
  const QColor background = _colorTable[DEFAULT_BACK_COLOR].color;
  const QColor foreground = _colorTable[DEFAULT_FORE_COLOR].color;
  const Character* style = &_image[loc(cursorPos.x(),cursorPos.y())];

  drawBackground(painter,rect,background);
  drawCursor(painter,rect,foreground,background,invertColors);
  drawCharacters(painter,rect,_inputMethodData.preeditString,style,invertColors);

  _inputMethodData.previousPreeditRect = rect;
}

FilterChain* TerminalView::filterChain() const
{
  return _filterChain;
}

void TerminalView::paintFilters(QPainter& painter)
{
  //qDebug("%s %d paintFilters", __FILE__, __LINE__);

  // get color of character under mouse and use it to draw
  // lines for filters
  QPoint cursorPos = mapFromGlobal(QCursor::pos());
  int cursorLine;
  int cursorColumn;
  getCharacterPosition( cursorPos , cursorLine , cursorColumn );
  Character cursorCharacter = _image[loc(cursorColumn,cursorLine)];

  painter.setPen( QPen(cursorCharacter.foregroundColor.color(colorTable())) );

  // iterate over hotspots identified by the display's currently active filters
  // and draw appropriate visuals to indicate the presence of the hotspot

  QList<Filter::HotSpot*> spots = _filterChain->hotSpots();
  QListIterator<Filter::HotSpot*> iter(spots);
  while (iter.hasNext())
    {
      Filter::HotSpot* spot = iter.next();

      for ( int line = spot->startLine() ; line <= spot->endLine() ; line++ )
        {
          int startColumn = 0;
          int endColumn = _columns-1; // TODO use number of _columns which are actually
          // occupied on this line rather than the width of the
          // display in _columns

          // ignore whitespace at the end of the lines
          while ( QChar(_image[loc(endColumn,line)].character).isSpace() && endColumn > 0 )
            endColumn--;

          // increment here because the column which we want to set 'endColumn' to
          // is the first whitespace character at the end of the line
          endColumn++;

          if ( line == spot->startLine() )
            startColumn = spot->startColumn();
          if ( line == spot->endLine() )
            endColumn = spot->endColumn();

          // subtract one pixel from
          // the right and bottom so that
          // we do not overdraw adjacent
          // hotspots
          //
          // subtracting one pixel from all sides also prevents an edge case where
          // moving the mouse outside a link could still leave it underlined
          // because the check below for the position of the cursor
          // finds it on the border of the target area
          QRect r;
          r.setCoords( startColumn*_fontWidth + 1, line*_fontHeight + 1,
                       endColumn*_fontWidth - 1, (line+1)*_fontHeight - 1 );

          // Underline link hotspots
          if ( spot->type() == Filter::Link ||
               spot->type() == Filter::ErrorLink)
            {
              QFontMetrics metrics(font());

              // find the baseline (which is the invisible line that the
              // characters in the font sit on
              int baseline = r.bottom() + 1;
              // find the position of the underline below that
              int underlinePos = baseline + metrics.underlinePos();

              if (r.contains (mapFromGlobal(QCursor::pos())))
                {
                  if (spot->type () == Filter::ErrorLink)
                    painter.setPen (QColor (255,0,0));
                  painter.drawLine (r.left(), underlinePos,
                                    r.right() + 2, underlinePos);
                }
            }
          // Marker hotspots simply have a transparent rectanglular shape
          // drawn on top of them
          else if ( spot->type() == Filter::Marker )
            {
              //TODO - Do not use a hardcoded colour for this
              painter.fillRect(r,QBrush(QColor(255,0,0,120)));
            }

        }
    }
}
void TerminalView::drawContents(QPainter &paint, const QRect &rect)
{
  //qDebug("%s %d drawContents and rect x=%d y=%d w=%d h=%d", __FILE__, __LINE__, rect.x(), rect.y(),rect.width(),rect.height());

  QPoint topLeft  = contentsRect().topLeft();
  // Take the topmost vertical position for the view.
  int topLeftY = topLeft.y();

  // In Konsole, the view has been centered. Don't do that here, since there
  // are strange hopping effects during a resize when the view does no match
  // exactly the widget width.
  // int topLeftX = (_contentWidth - _usedColumns * _fontWidth) / 2;
  int topLeftX = 0;

  int leftUpperX = qMin(_usedColumns-1, qMax(0, qFloor((rect.left()   - topLeftX - _leftMargin ) / _fontWidth)));
  int leftUpperY = qMin(_usedLines-1,  qMax(0, qFloor((rect.top()    - topLeftY - _topMargin  ) / _fontHeight)));
  int rightLowerX = qMin(_usedColumns-1, qMax(0, qFloor((rect.right()  - topLeftX - _leftMargin ) / _fontWidth)));
  int rightLowerY = qMin(_usedLines-1,  qMax(0, qFloor((rect.bottom() - topLeftY - _topMargin  ) / _fontHeight)));

  const int bufferSize = _usedColumns;
  QChar *disstrU = new QChar[bufferSize];
  for (int y = leftUpperY; y <= rightLowerY; y++)
    {
      quint16 c = _image[loc(leftUpperX,y)].character;
      int x = leftUpperX;
      if(!c && x)
        x--; // Search for start of multi-column character
      for (; x <= rightLowerX; x++)
        {
          int len = 1;
          int p = 0;

          // is this a single character or a sequence of characters ?
          if ( _image[loc(x,y)].rendition & RE_EXTENDED_CHAR )
            {
              // sequence of characters
              ushort extendedCharLength = 0;
              ushort* chars = ExtendedCharTable::instance
                  .lookupExtendedChar(_image[loc(x,y)].charSequence,extendedCharLength);
              for ( int index = 0 ; index < extendedCharLength ; index++ )
                {
                  Q_ASSERT( p < bufferSize );
                  disstrU[p++] = chars[index];
                }
            }
          else
            {
              // single character
              c = _image[loc(x,y)].character;
              if (c)
                {
                  Q_ASSERT( p < bufferSize );
                  disstrU[p++] = c; //fontMap(c);
                }
            }

          bool doubleWidth = (_image[ qMin(loc(x,y)+1,_imageSize) ].character == 0);
          CharacterColor currentForeground = _image[loc(x,y)].foregroundColor;
          CharacterColor currentBackground = _image[loc(x,y)].backgroundColor;
          quint8 currentRendition = _image[loc(x,y)].rendition;

          while (x+len <= rightLowerX &&
                 _image[loc(x+len,y)].foregroundColor == currentForeground &&
                 _image[loc(x+len,y)].backgroundColor == currentBackground &&
                 _image[loc(x+len,y)].rendition == currentRendition &&
                 (_image[ qMin(loc(x+len,y)+1,_imageSize) ].character == 0) == doubleWidth)
            {
              c = _image[loc(x+len,y)].character;
              if (c)
                disstrU[p++] = c; //fontMap(c);
              if (doubleWidth) // assert((_image[loc(x+len,y)+1].character == 0)), see above if condition
                len++; // Skip trailing part of multi-column character
              len++;
            }
          if ((x+len < _usedColumns) && (!_image[loc(x+len,y)].character))
            len++; // Adjust for trailing part of multi-column character

          bool save__fixedFont = _fixedFont;
          if (doubleWidth)
            _fixedFont = false;
          QString unistr(disstrU,p);

          if (y < _lineProperties.size())
            {
              if (_lineProperties[y] & LINE_DOUBLEWIDTH) {
                  paint.scale(2,1);
                }

              if (_lineProperties[y] & LINE_DOUBLEHEIGHT) {
                  paint.scale(1,2);
                }
            }

          // calculate the area in which the text will be drawn
          QRect textArea = QRect( _leftMargin+topLeftX+_fontWidth*x ,
                                  _topMargin+topLeftY+_fontHeight*y ,
                                  _fontWidth*len,
                                  _fontHeight);

          // move the calculated area to take account of scaling applied to the painter.
          // the position of the area from the origin (0,0) is scaled
          // by the opposite of whatever
          // transformation has been applied to the painter.  this ensures that
          // painting does actually start from textArea.topLeft()
          // (instead of textArea.topLeft() * painter-scale)
          QTransform inverted = paint.transform().inverted();
          textArea.moveCenter( inverted.map(textArea.center()) );


          //paint text fragment
          drawTextFragment(	paint,
                              textArea,
                              unistr,
                              &_image[loc(x,y)] );


          _fixedFont = save__fixedFont;

          //reset back to single-width, single-height _lines
          paint.resetTransform();

          if (y < _lineProperties.size()-1)
            {
              //double-height _lines are represented by two adjacent _lines
              //containing the same characters
              //both _lines will have the LINE_DOUBLEHEIGHT attribute.
              //If the current line has the LINE_DOUBLEHEIGHT attribute,
              //we can therefore skip the next line
              if (_lineProperties[y] & LINE_DOUBLEHEIGHT)
                y++;
            }
          x += len - 1;
        } // for x
    } // for y
  delete [] disstrU;
}

void TerminalView::blinkEvent()
{
  _blinking = !_blinking;

  //TODO:  Optimise to only repaint the areas of the widget
  // where there is blinking text
  // rather than repainting the whole widget.
  update();
}

QRect TerminalView::imageToWidget(const QRect& imageArea) const
{
  //qDebug("%s %d imageToWidget", __FILE__, __LINE__);
  QRect result;
  result.setLeft( _leftMargin + _fontWidth * imageArea.left() );
  result.setTop( _topMargin + _fontHeight * imageArea.top() );
  result.setWidth( _fontWidth * imageArea.width() );
  result.setHeight( _fontHeight * imageArea.height() );

  return result;
}

void TerminalView::blinkCursorEvent()
{
  if (_hasBlinkingCursor)
    _cursorBlinking = !_cursorBlinking;
  else
    _cursorBlinking = false;

  QRect cursorRect = imageToWidget( QRect(cursorPosition(),QSize(1,1)) );

  update(cursorRect);
}

/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                                  Resizing                                 */
/*                                                                           */
/* ------------------------------------------------------------------------- */

void TerminalView::resizeEvent(QResizeEvent*)
{
  updateImageSize();
}

void TerminalView::propagateSize()
{
  if (_isFixedSize)
    {
      setSize(_columns, _lines);
      QWidget::setFixedSize(sizeHint());
      parentWidget()->adjustSize();
      parentWidget()->setFixedSize(parentWidget()->sizeHint());
      return;
    }
  if (_image)
    updateImageSize();
}

void TerminalView::updateImageSize()
{
  //qDebug("%s %d updateImageSize", __FILE__, __LINE__);
  Character* oldimg = _image;
  int oldlin = _lines;
  int oldcol = _columns;

  makeImage();


  // copy the old image to reduce flicker
  int lines = qMin(oldlin,_lines);
  int columns = qMin(oldcol,_columns);

  //qDebug("%s %d updateImageSize", __FILE__, __LINE__);
  if (oldimg)
    {
      for (int line = 0; line < lines; line++)
        {
          memcpy((void*)&_image[_columns*line],
                 (void*)&oldimg[oldcol*line],columns*sizeof(Character));
        }
      delete[] oldimg;
    }

  //qDebug("%s %d updateImageSize", __FILE__, __LINE__);
  if (_screenWindow)
    _screenWindow->setWindowLines(_lines);

  _resizing = (oldlin!=_lines) || (oldcol!=_columns);

  if ( _resizing )
    {
      //qDebug("%s %d updateImageSize", __FILE__, __LINE__);
      showResizeNotification();
#if defined (SIGWINCH)
      ::raise (SIGWINCH);
#endif
      emit changedContentSizeSignal(_contentHeight, _contentWidth); // expose resizeEvent
    }
  //qDebug("%s %d updateImageSize", __FILE__, __LINE__);

  _resizing = false;
}

//showEvent and hideEvent are reimplemented here so that it appears to other classes that the
//display has been resized when the display is hidden or shown.
//
//this allows
//TODO: Perhaps it would be better to have separate signals for show and hide instead of using
//the same signal as the one for a content size change
void TerminalView::showEvent(QShowEvent*)
{
  emit changedContentSizeSignal(_contentHeight,_contentWidth);
}
void TerminalView::hideEvent(QHideEvent*)
{
  emit changedContentSizeSignal(_contentHeight,_contentWidth);
}

/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                                Scrollbar                                  */
/*                                                                           */
/* ------------------------------------------------------------------------- */

void TerminalView::scrollBarPositionChanged(int)
{
  if ( !_screenWindow )
    return;

  _screenWindow->scrollTo( _scrollBar->value() );

  // if the thumb has been moved to the bottom of the _scrollBar then set
  // the display to automatically track new output,
  // that is, scroll down automatically
  // to how new _lines as they are added
  const bool atEndOfOutput = (_scrollBar->value() == _scrollBar->maximum());
  _screenWindow->setTrackOutput( atEndOfOutput );

  updateImage();
}

void TerminalView::setScroll(int cursor, int slines)
{
  //qDebug("%s %d setScroll", __FILE__, __LINE__);
  // update _scrollBar if the range or value has changed,
  // otherwise return
  //
  // setting the range or value of a _scrollBar will always trigger
  // a repaint, so it should be avoided if it is not necessary
  if ( _scrollBar->minimum() == 0                 &&
       _scrollBar->maximum() == (slines - _lines) &&
       _scrollBar->value()   == cursor )
    {
      return;
    }

  disconnect(_scrollBar, SIGNAL(valueChanged(int)), this, SLOT(scrollBarPositionChanged(int)));
  _scrollBar->setRange(0,slines - _lines);
  _scrollBar->setSingleStep(1);
  _scrollBar->setPageStep(_lines);
  _scrollBar->setValue(cursor);
  connect(_scrollBar, SIGNAL(valueChanged(int)), this, SLOT(scrollBarPositionChanged(int)));
}

void TerminalView::setScrollBarPosition(ScrollBarPosition position)
{
  if (_scrollbarLocation == position) {
      //      return;
    }

  if ( position == NoScrollBar )
    _scrollBar->hide();
  else
    _scrollBar->show();

  _topMargin = _leftMargin = 1;
  _scrollbarLocation = position;

  propagateSize();
  update();
}

void TerminalView::mousePressEvent(QMouseEvent* ev)
{
  if ( _possibleTripleClick && (ev->button()==Qt::LeftButton) ) {
      mouseTripleClickEvent(ev);
      return;
    }

  if ( !contentsRect().contains(ev->pos()) ) return;

  if ( !_screenWindow ) return;

  int charLine;
  int charColumn;
  getCharacterPosition(ev->pos(),charLine,charColumn);
  QPoint pos = QPoint(charColumn,charLine);

  if ( ev->button() == Qt::LeftButton)
    {

      Filter::HotSpot* spot = _filterChain->hotSpotAt(charLine,charColumn);
      if ( spot &&
          (spot->type() == Filter::Link || spot->type() == Filter::ErrorLink))
        {
          QList<QAction*> actions = spot->actions ();
          if (actions.length ())
            actions.at (0)->activate (QAction::Trigger);
          return;
        }

      _lineSelectionMode = false;
      _wordSelectionMode = false;

      emit isBusySelecting(true); // Keep it steady...
      // Drag only when the Control key is hold
      bool selected = false;

      // The receiver of the testIsSelected() signal will adjust
      // 'selected' accordingly.
      //emit testIsSelected(pos.x(), pos.y(), selected);

      selected =  _screenWindow->isSelected(pos.x(),pos.y());

      if ((!_ctrlDrag || ev->modifiers() & Qt::ControlModifier) && selected ) {
          // The user clicked inside selected text
          dragInfo.state = diPending;
          dragInfo.start = ev->pos();
        }
      else {
          // No reason to ever start a drag event
          dragInfo.state = diNone;

          _preserveLineBreaks = !( ( ev->modifiers() & Qt::ControlModifier ) && !(ev->modifiers() & Qt::AltModifier) );
          _columnSelectionMode = (ev->modifiers() & Qt::AltModifier) && (ev->modifiers() & Qt::ControlModifier);

          if (_mouseMarks || (ev->modifiers() & Qt::ShiftModifier))
            {
              _screenWindow->clearSelection();

              //emit clearSelectionSignal();
              pos.ry() += _scrollBar->value();
              _iPntSel = _pntSel = pos;
              _actSel = 1; // left mouse button pressed but nothing selected yet.

            }
          else
            {
              emit mouseSignal( 0, charColumn + 1, charLine + 1 +_scrollBar->value() -_scrollBar->maximum() , 0);
            }
        }
    }
  else if ( ev->button() == Qt::MiddleButton )
    {
      if ( _mouseMarks || (!_mouseMarks && (ev->modifiers() & Qt::ShiftModifier)) )
        emitSelection(true,ev->modifiers() & Qt::ControlModifier);
      else
        emit mouseSignal( 1, charColumn +1, charLine +1 +_scrollBar->value() -_scrollBar->maximum() , 0);
    }
  else if ( ev->button() == Qt::RightButton )
    {
      if (_mouseMarks || (ev->modifiers() & Qt::ShiftModifier))
        {
          emit configureRequest( this,
                                 ev->modifiers() & (Qt::ShiftModifier|Qt::ControlModifier),
                                 ev->pos()
                                 );
        }
      else
        emit mouseSignal( 2, charColumn +1, charLine +1 +_scrollBar->value() -_scrollBar->maximum() , 0);
    }

  QWidget::mousePressEvent (ev);
}

QList<QAction*> TerminalView::filterActions(const QPoint& position)
{
  int charLine, charColumn;
  getCharacterPosition(position,charLine,charColumn);

  Filter::HotSpot* spot = _filterChain->hotSpotAt(charLine,charColumn);

  return spot ? spot->actions() : QList<QAction*>();
}

void TerminalView::mouseMoveEvent(QMouseEvent* ev)
{
  int charLine = 0;
  int charColumn = 0;

  getCharacterPosition(ev->pos(),charLine,charColumn);

  // handle filters
  // change link hot-spot appearance on mouse-over
  Filter::HotSpot* spot = _filterChain->hotSpotAt(charLine,charColumn);
  if ( spot &&
      (spot->type() == Filter::Link || spot->type() == Filter::ErrorLink))
    {
      // change mouse cursor when mouse is over links
      if (! _mouseOverHotspotArea.isValid())
        setCursor (Qt::PointingHandCursor);

      QRect previousHotspotArea = _mouseOverHotspotArea;
      _mouseOverHotspotArea.setCoords( qMin(spot->startColumn() , spot->endColumn()) * _fontWidth,
                                       spot->startLine() * _fontHeight,
                                       qMax(spot->startColumn() , spot->endColumn()) * _fontHeight,
                                       (spot->endLine()+1) * _fontHeight );

      // display tooltips when mousing over links
      // TODO: Extend this to work with filter types other than links
      const QString& tooltip = spot->tooltip();
      if ( !tooltip.isEmpty() )
        {
          QToolTip::showText( mapToGlobal(ev->pos()) , tooltip , this , _mouseOverHotspotArea );
        }

      update( _mouseOverHotspotArea | previousHotspotArea );
    }
  else if ( _mouseOverHotspotArea.isValid() )
    {
      setUsesMouse (true);
      update( _mouseOverHotspotArea );
      // set hotspot area to an invalid rectangle
      _mouseOverHotspotArea = QRect();
    }

  // for auto-hiding the cursor, we need mouseTracking
  if (ev->buttons() == Qt::NoButton ) return;

  // if the terminal is interested in mouse movements
  // then emit a mouse movement signal, unless the shift
  // key is being held down, which overrides this.
  if (!_mouseMarks && !(ev->modifiers() & Qt::ShiftModifier))
    {
      int button = 3;
      if (ev->buttons() & Qt::LeftButton)
        button = 0;
      if (ev->buttons() & Qt::MiddleButton)
        button = 1;
      if (ev->buttons() & Qt::RightButton)
        button = 2;


      emit mouseSignal( button,
                        charColumn + 1,
                        charLine + 1 +_scrollBar->value() -_scrollBar->maximum(),
                        1 );

      return;
    }

  if (dragInfo.state == diPending)
    {
      // we had a mouse down, but haven't confirmed a drag yet
      // if the mouse has moved sufficiently, we will confirm

      int distance = 10; //KGlobalSettings::dndEventDelay();
      if ( ev->x() > dragInfo.start.x() + distance || ev->x() < dragInfo.start.x() - distance ||
           ev->y() > dragInfo.start.y() + distance || ev->y() < dragInfo.start.y() - distance)
        {
          // we've left the drag square, we can start a real drag operation now
          emit isBusySelecting(false); // Ok.. we can breath again.

          _screenWindow->clearSelection();
          doDrag();
        }
      return;
    }
  else if (dragInfo.state == diDragging)
    {
      // this isn't technically needed because mouseMoveEvent is suppressed during
      // Qt drag operations, replaced by dragMoveEvent
      return;
    }

  if (_actSel == 0) return;

  // don't extend selection while pasting
  if (ev->buttons() & Qt::MiddleButton) return;

  extendSelection( ev->pos() );
}

void TerminalView::extendSelection(const QPoint& position) {
  QPoint pos = position;

  if (!_screenWindow) {
      return;
    }

  QPoint tL  = contentsRect().topLeft();
  int    tLx = tL.x();
  int    tLy = tL.y();
  int    scroll = _scrollBar->value();

  // we're in the process of moving the mouse with the left button pressed
  // the mouse cursor will kept caught within the bounds of the text in
  // this widget.

  // Adjust position within text area bounds. See FIXME above.
  if (pos.x() < tLx + _leftMargin) {
      pos.setX(tLx + _leftMargin);
    }
  if (pos.x() > tLx + _leftMargin + _usedColumns * _fontWidth - 1) {
      pos.setX(tLx + _leftMargin + _usedColumns * _fontWidth);
    }
  if (pos.y() < tLy + _topMargin) {
      pos.setY(tLy + _topMargin);
    }
  if (pos.y() > tLy + _topMargin + _usedLines * _fontHeight - 1) {
      pos.setY(tLy + _topMargin + _usedLines * _fontHeight - 1);
    }

  if (pos.y() == tLy + _topMargin + _usedLines * _fontHeight - 1) {
      _scrollBar->setValue(_scrollBar->value() + yMouseScroll); // scrollforward
    }
  if (pos.y() == tLy + _topMargin) {
      _scrollBar->setValue(_scrollBar->value() - yMouseScroll); // scrollback
    }

  int charColumn = 0;
  int charLine = 0;
  getCharacterPosition(pos, charLine, charColumn);

  QPoint here = QPoint(charColumn, charLine);
  QPoint ohere(here);
  QPoint _iPntSelCorr = _iPntSel;
  _iPntSelCorr.ry() -= _scrollBar->value();
  QPoint _pntSelCorr = _pntSel;
  _pntSelCorr.ry() -= _scrollBar->value();
  bool swapping = false;

  if (_wordSelectionMode) {
      // Extend to word boundaries
      int i = 0;
      int selClass = 0;

      bool left_not_right = (here.y() < _iPntSelCorr.y() ||
                             (here.y() == _iPntSelCorr.y() && here.x() < _iPntSelCorr.x()));
      bool old_left_not_right = (_pntSelCorr.y() < _iPntSelCorr.y() ||
                                 (_pntSelCorr.y() == _iPntSelCorr.y() && _pntSelCorr.x() < _iPntSelCorr.x()));
      swapping = left_not_right != old_left_not_right;

      // Find left (left_not_right ? from here : from start)
      QPoint left = left_not_right ? here : _iPntSelCorr;
      i = loc(left.x(), left.y());
      if (i >= 0 && i <= _imageSize) {
          selClass = charClass(_image[i].character);
          while (((left.x() > 0) || (left.y() > 0 && (_lineProperties[left.y() - 1] & LINE_WRAPPED)))
                 && charClass(_image[i - 1].character) == selClass) {
              i--;
              if (left.x() > 0) {
                  left.rx()--;
                } else {
                  left.rx() = _usedColumns - 1;
                  left.ry()--;
                }
            }
        }

      // Find left (left_not_right ? from start : from here)
      QPoint right = left_not_right ? _iPntSelCorr : here;
      i = loc(right.x(), right.y());
      if (i >= 0 && i <= _imageSize) {
          selClass = charClass(_image[i].character);
          while (((right.x() < _usedColumns - 1) || (right.y() < _usedLines - 1 && (_lineProperties[right.y()] & LINE_WRAPPED)))
                 && charClass(_image[i + 1].character) == selClass) {
              i++;
              if (right.x() < _usedColumns - 1) {
                  right.rx()++;
                } else {
                  right.rx() = 0;
                  right.ry()++;
                }
            }
        }

      // Pick which is start (ohere) and which is extension (here)
      if (left_not_right) {
          here = left;
          ohere = right;
        } else {
          here = right;
          ohere = left;
        }
      ohere.rx()++;
    }

  if (_lineSelectionMode) {
      // Extend to complete line
      bool above_not_below = (here.y() < _iPntSelCorr.y());

      QPoint above = above_not_below ? here : _iPntSelCorr;
      QPoint below = above_not_below ? _iPntSelCorr : here;

      while (above.y() > 0 && (_lineProperties[above.y() - 1] & LINE_WRAPPED)) {
          above.ry()--;
        }
      while (below.y() < _usedLines - 1 && (_lineProperties[below.y()] & LINE_WRAPPED)) {
          below.ry()++;
        }

      above.setX(0);
      below.setX(_usedColumns - 1);

      // Pick which is start (ohere) and which is extension (here)
      if (above_not_below) {
          here = above;
          ohere = below;
        } else {
          here = below;
          ohere = above;
        }

      QPoint newSelBegin = QPoint(ohere.x(), ohere.y());
      swapping = !(_tripleSelBegin == newSelBegin);
      _tripleSelBegin = newSelBegin;

      ohere.rx()++;
    }

  int offset = 0;
  if (!_wordSelectionMode && !_lineSelectionMode) {
      int i = 0;
      int selClass = 0;

      bool left_not_right = (here.y() < _iPntSelCorr.y() ||
                             (here.y() == _iPntSelCorr.y() && here.x() < _iPntSelCorr.x()));
      bool old_left_not_right = (_pntSelCorr.y() < _iPntSelCorr.y() ||
                                 (_pntSelCorr.y() == _iPntSelCorr.y() && _pntSelCorr.x() < _iPntSelCorr.x()));
      swapping = left_not_right != old_left_not_right;

      // Find left (left_not_right ? from here : from start)
      QPoint left = left_not_right ? here : _iPntSelCorr;

      // Find left (left_not_right ? from start : from here)
      QPoint right = left_not_right ? _iPntSelCorr : here;
      if (right.x() > 0 && !_columnSelectionMode) {
          i = loc(right.x(), right.y());
          if (i >= 0 && i <= _imageSize) {
              selClass = charClass(_image[i - 1].character);
              if (selClass == ' ') {
                  while (right.x() < _usedColumns - 1 && charClass(_image[i + 1].character) == selClass && (right.y() < _usedLines - 1) &&
                         !(_lineProperties[right.y()] & LINE_WRAPPED)) {
                      i++;
                      right.rx()++;
                    }
                  if (right.x() < _usedColumns - 1) {
                      right = left_not_right ? _iPntSelCorr : here;
                    } else {
                      right.rx()++;  // will be balanced later because of offset=-1;
                    }
                }
            }
        }

      // Pick which is start (ohere) and which is extension (here)
      if (left_not_right) {
          here = left;
          ohere = right;
          offset = 0;
        } else {
          here = right;
          ohere = left;
          offset = -1;
        }
    }

  if ((here == _pntSelCorr) && (scroll == _scrollBar->value())) {
      return; // not moved
    }

  if (here == ohere) {
      return; // It's not left, it's not right.
    }

  if (_actSel < 2 || swapping) {
      if (_columnSelectionMode && !_lineSelectionMode && !_wordSelectionMode) {
          _screenWindow->setSelectionStart(ohere.x(), ohere.y(), true);
        } else {
          _screenWindow->setSelectionStart(ohere.x() - 1 - offset , ohere.y(), false);
        }

    }

  _actSel = 2; // within selection
  _pntSel = here;
  _pntSel.ry() += _scrollBar->value();

  if (_columnSelectionMode && !_lineSelectionMode && !_wordSelectionMode) {
      _screenWindow->setSelectionEnd(here.x(), here.y());
    } else {
      _screenWindow->setSelectionEnd(here.x() + offset, here.y());
    }
}

void TerminalView::mouseReleaseEvent(QMouseEvent* ev)
{
  if ( !_screenWindow )
    return;

  int charLine;
  int charColumn;
  getCharacterPosition(ev->pos(),charLine,charColumn);

  if ( ev->button() == Qt::LeftButton)
    {
      emit isBusySelecting(false);
      if(dragInfo.state == diPending)
        {
          // We had a drag event pending but never confirmed.  Kill selection
          _screenWindow->clearSelection();
          //emit clearSelectionSignal();
        }
      else
        {
          if ( _actSel > 1 )
            {
              setSelection(  _screenWindow->selectedText(_preserveLineBreaks)  );
            }

          _actSel = 0;

          //FIXME: emits a release event even if the mouse is
          //       outside the range. The procedure used in `mouseMoveEvent'
          //       applies here, too.

          if (!_mouseMarks && !(ev->modifiers() & Qt::ShiftModifier))
            emit mouseSignal( 3, // release
                              charColumn + 1,
                              charLine + 1 +_scrollBar->value() -_scrollBar->maximum() , 0);
        }
      dragInfo.state = diNone;
    }


  if ( !_mouseMarks &&
       ((ev->button() == Qt::RightButton && !(ev->modifiers() & Qt::ShiftModifier))
        || ev->button() == Qt::MiddleButton) )
    {
      emit mouseSignal( 3,
                        charColumn + 1,
                        charLine + 1 +_scrollBar->value() -_scrollBar->maximum() ,
                        0);
    }

  QWidget::mouseReleaseEvent(ev);
}

void TerminalView::getCharacterPosition(const QPoint& widgetPoint,int& line,int& column) const
{

  column = (widgetPoint.x() + _fontWidth/2 -contentsRect().left()-_leftMargin) / _fontWidth;
  line = (widgetPoint.y()-contentsRect().top()-_topMargin) / _fontHeight;

  if ( line < 0 )
    line = 0;
  if ( column < 0 )
    column = 0;

  if ( line >= _usedLines )
    line = _usedLines-1;

  // the column value returned can be equal to _usedColumns, which
  // is the position just after the last character displayed in a line.
  //
  // this is required so that the user can select characters in the right-most
  // column (or left-most for right-to-left input)
  if ( column > _usedColumns )
    column = _usedColumns;
}

void TerminalView::updateLineProperties()
{
  if ( !_screenWindow )
    return;

  _lineProperties = _screenWindow->getLineProperties();
}

void TerminalView::mouseDoubleClickEvent(QMouseEvent* ev)
{
  if ( ev->button() != Qt::LeftButton) return;
  if ( !_screenWindow ) return;

  int charLine = 0;
  int charColumn = 0;

  getCharacterPosition(ev->pos(),charLine,charColumn);

  QPoint pos(charColumn,charLine);

  // pass on double click as two clicks.
  if (!_mouseMarks && !(ev->modifiers() & Qt::ShiftModifier))
    {
      // Send just _ONE_ click event, since the first click of the double click
      // was already sent by the click handler
      emit mouseSignal( 0,
                        pos.x()+1,
                        pos.y()+1 +_scrollBar->value() -_scrollBar->maximum(),
                        0 ); // left button
      return;
    }

  _screenWindow->clearSelection();
  QPoint bgnSel = pos;
  QPoint endSel = pos;
  int i = loc(bgnSel.x(),bgnSel.y());
  _iPntSel = bgnSel;
  _iPntSel.ry() += _scrollBar->value();

  _wordSelectionMode = true;

  // find word boundaries...
  int selClass = charClass(_image[i].character);
  {
    // find the start of the word
    int x = bgnSel.x();
    while ( ((x>0) || (bgnSel.y()>0 && (_lineProperties[bgnSel.y()-1] & LINE_WRAPPED) ))
            && charClass(_image[i-1].character) == selClass )
      {
        i--;
        if (x>0)
          x--;
        else
          {
            x=_usedColumns-1;
            bgnSel.ry()--;
          }
      }

    bgnSel.setX(x);
    _screenWindow->setSelectionStart( bgnSel.x() , bgnSel.y() , false );

    // find the end of the word
    i = loc( endSel.x(), endSel.y() );
    x = endSel.x();
    while( ((x<_usedColumns-1) || (endSel.y()<_usedLines-1 && (_lineProperties[endSel.y()] & LINE_WRAPPED) ))
           && charClass(_image[i+1].character) == selClass )
      {
        i++;
        if (x<_usedColumns-1)
          x++;
        else
          {
            x=0;
            endSel.ry()++;
          }
      }

    endSel.setX(x);

    // In word selection mode don't select @ (64) if at end of word.
    if ( ( QChar( _image[i].character ) == '@' ) && ( ( endSel.x() - bgnSel.x() ) > 0 ) )
      endSel.setX( x - 1 );


    _actSel = 2; // within selection

    _screenWindow->setSelectionEnd( endSel.x() , endSel.y() );

    setSelection( _screenWindow->selectedText(_preserveLineBreaks) );
  }

  _possibleTripleClick=true;

  QTimer::singleShot(QApplication::doubleClickInterval(),this,
                     SLOT(tripleClickTimeout()));
}

void TerminalView::wheelEvent( QWheelEvent* ev )
{
  if (ev->angleDelta().y() == 0)
    return;

  if ( _mouseMarks )
    _scrollBar->event(ev);
  else
    {
      int charLine;
      int charColumn;
#if defined (HAVE_QWHEELEVENT_POSITION)
      QPoint pos = ev->position().toPoint();
#else
      QPoint pos = ev->pos();
#endif
      getCharacterPosition( pos , charLine , charColumn );

      int delta = ev->angleDelta().y();

      emit mouseSignal( delta > 0 ? 4 : 5,
                        charColumn + 1,
                        charLine + 1 +_scrollBar->value() -_scrollBar->maximum() ,
                        0);
    }
}

void TerminalView::tripleClickTimeout()
{
  _possibleTripleClick=false;
}

void TerminalView::mouseTripleClickEvent(QMouseEvent* ev)
{
  if ( !_screenWindow ) return;

  int charLine;
  int charColumn;
  getCharacterPosition(ev->pos(),charLine,charColumn);
  _iPntSel = QPoint(charColumn,charLine);

  _screenWindow->clearSelection();

  _lineSelectionMode = true;
  _wordSelectionMode = false;

  _actSel = 2; // within selection
  emit isBusySelecting(true); // Keep it steady...

  while (_iPntSel.y()>0 && (_lineProperties[_iPntSel.y()-1] & LINE_WRAPPED) )
    _iPntSel.ry()--;

  if (_tripleClickMode == SelectForwardsFromCursor) {
      // find word boundary start
      int i = loc(_iPntSel.x(),_iPntSel.y());
      int selClass = charClass(_image[i].character);
      int x = _iPntSel.x();

      while ( ((x>0) ||
               (_iPntSel.y()>0 && (_lineProperties[_iPntSel.y()-1] & LINE_WRAPPED) )
               )
              && charClass(_image[i-1].character) == selClass )
        {
          i--;
          if (x>0)
            x--;
          else
            {
              x=_columns-1;
              _iPntSel.ry()--;
            }
        }

      _screenWindow->setSelectionStart( x , _iPntSel.y() , false );
      _tripleSelBegin = QPoint( x, _iPntSel.y() );
    }
  else if (_tripleClickMode == SelectWholeLine) {
      _screenWindow->setSelectionStart( 0 , _iPntSel.y() , false );
      _tripleSelBegin = QPoint( 0, _iPntSel.y() );
    }

  while (_iPntSel.y()<_lines-1 && (_lineProperties[_iPntSel.y()] & LINE_WRAPPED) )
    _iPntSel.ry()++;

  _screenWindow->setSelectionEnd( _columns - 1 , _iPntSel.y() );

  setSelection(_screenWindow->selectedText(_preserveLineBreaks));

  _iPntSel.ry() += _scrollBar->value();

  emit tripleClicked( _screenWindow->selectedText( _preserveLineBreaks ) );
}


bool TerminalView::focusNextPrevChild( bool next )
{
  if (next)
    return false; // This disables changing the active part in konqueror
  // when pressing Tab
  return QWidget::focusNextPrevChild( next );
}


int TerminalView::charClass(quint16 ch) const
{
  QChar qch=QChar(ch);
  if ( qch.isSpace() ) return ' ';

  if ( qch.isLetterOrNumber() || _wordCharacters.contains(qch, Qt::CaseInsensitive ) )
    return 'a';

  // Everything else is weird
  return 1;
}

void TerminalView::setWordCharacters(const QString& wc)
{
  _wordCharacters = wc;
}

void TerminalView::setUsesMouse(bool on)
{
  _mouseMarks = on;
  setCursor( _mouseMarks ? Qt::IBeamCursor : Qt::ArrowCursor );
}
bool TerminalView::usesMouse() const
{
  return _mouseMarks;
}

void TerminalView::setBracketedPasteMode(bool on)
{
  _bracketedPasteMode = on;
}
bool TerminalView::bracketedPasteMode() const
{
    return _bracketedPasteMode;
}


/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                               Clipboard                                   */
/*                                                                           */
/* ------------------------------------------------------------------------- */

#undef KeyPress

void TerminalView::emitSelection(bool useXselection,bool appendReturn)
{
  if ( !_screenWindow )
    return;

  // Paste Clipboard by simulating keypress events
  QString text = QApplication::clipboard()->text(useXselection ? QClipboard::Selection :
                                                                 QClipboard::Clipboard);
  if(appendReturn)
    text.append("\r");
  if ( ! text.isEmpty() )
    {
      text.replace("\n", "\r");
      if (bracketedPasteMode() && !_disabledBracketedPasteMode)
        bracketText(text);
      else if (text.contains ("\t"))
        {
          qWarning ("converting TAB to SPC in pasted text before processing");
          text.replace ("\t", " ");
        }
      QKeyEvent e(QEvent::KeyPress, 0, Qt::NoModifier, text);
      emit keyPressedSignal(&e); // expose as a big fat keypress event

      _screenWindow->clearSelection();
    }
}

void TerminalView::bracketText(QString& text)
{
    text.prepend("\033[200~");
    text.append("\033[201~");
}

void TerminalView::setSelection(const QString& t)
{
  QApplication::clipboard()->setText(t, QClipboard::Selection);
}

void TerminalView::copyClipboard(bool extra_interrupt)
{
  if ( !_screenWindow || !hasFocus())
    return;

  QString text = _screenWindow->selectedText(_preserveLineBreaks);

  if (text.isEmpty ())
    {
      if (! extra_interrupt)
        emit interrupt_signal ();
    }
  else
    QApplication::clipboard()->setText(text);
}

void TerminalView::pasteClipboard()
{
  if(hasFocus ())
    {
      emitSelection(false,false);
    }
}

void TerminalView::selectAll()
{
  if ( !_screenWindow || !hasFocus())
    return;

  _screenWindow->setSelectionStart(0,-_screenWindow->currentLine(), false);
  //_screenWindow->setSelectionEnd(_screenWindow->windowColumns(),
  //                               _screenWindow->windowLines());

  _screenWindow->setSelectionEnd(_screenWindow->columnCount(),
                                 _screenWindow->windowLines());
}


void TerminalView::pasteSelection()
{
  emitSelection(true,false);
}


/* ------------------------------------------------------------------------- */
/*                                                                           */
/*                                Keyboard                                   */
/*                                                                           */
/* ------------------------------------------------------------------------- */

void TerminalView::keyPressEvent( QKeyEvent* event )
{
  //qDebug("%s %d keyPressEvent and key is %d", __FILE__, __LINE__, event->key());

  bool emitKeyPressSignal = true;

  // Keyboard-based navigation
  if ( event->modifiers() == Qt::ShiftModifier )
    {
      bool update = true;

      if ( event->key() == Qt::Key_PageUp )
        {
          //qDebug("%s %d pageup", __FILE__, __LINE__);
          _screenWindow->scrollBy( ScreenWindow::ScrollPages , -1 );
        }
      else if ( event->key() == Qt::Key_PageDown )
        {
          //qDebug("%s %d pagedown", __FILE__, __LINE__);
          _screenWindow->scrollBy( ScreenWindow::ScrollPages , 1 );
        }
      else if ( event->key() == Qt::Key_Up )
        {
          //qDebug("%s %d keyup", __FILE__, __LINE__);
          _screenWindow->scrollBy( ScreenWindow::ScrollLines , -1 );
        }
      else if ( event->key() == Qt::Key_Down )
        {
          //qDebug("%s %d keydown", __FILE__, __LINE__);
          _screenWindow->scrollBy( ScreenWindow::ScrollLines , 1 );
        }
      else {
          update = false;
        }

      if ( update )
        {
          //qDebug("%s %d updating", __FILE__, __LINE__);
          _screenWindow->setTrackOutput( _screenWindow->atEndOfOutput() );

          updateLineProperties();
          updateImage();

          // do not send key press to terminal
          emitKeyPressSignal = false;
        }
    }

  _screenWindow->setTrackOutput( true );

  _actSel=0; // Key stroke implies a screen update, so TerminalDisplay won't
  // know where the current selection is.

  if (_hasBlinkingCursor)
    {
      _blinkCursorTimer->start(BLINK_DELAY);
      if (_cursorBlinking)
        blinkCursorEvent();
      else
        _cursorBlinking = false;
    }

  if ( emitKeyPressSignal && !_readonly )
    emit keyPressedSignal(event);

  if (_readonly) {
      event->ignore();
    }
  else {
      event->accept();
    }
}

void TerminalView::inputMethodEvent( QInputMethodEvent* event )
{
  QKeyEvent keyEvent(QEvent::KeyPress,0,Qt::NoModifier,event->commitString());
  emit keyPressedSignal(&keyEvent);

  _inputMethodData.preeditString = event->preeditString();
  update(preeditRect() | _inputMethodData.previousPreeditRect);

  event->accept();
}
QVariant TerminalView::inputMethodQuery( Qt::InputMethodQuery query ) const
{
  const QPoint cursorPos = _screenWindow ? _screenWindow->cursorPosition() : QPoint(0,0);
  switch ( query )
    {
#if defined (HAVE_QT_IMCURSORRECTANGLE_ENUM_VALUE)
    case Qt::ImCursorRectangle:
#else
    case Qt::ImMicroFocus:
#endif
      return imageToWidget(QRect(cursorPos.x(),cursorPos.y(),1,1));
      break;
    case Qt::ImFont:
      return font();
      break;
    case Qt::ImCursorPosition:
      // return the cursor position within the current line
      return cursorPos.x();
      break;
    case Qt::ImSurroundingText:
      {
        // return the text from the current line
        QString lineText;
        QTextStream stream(&lineText);
        PlainTextDecoder decoder;
        decoder.begin(&stream);
        decoder.decodeLine(&_image[loc(0,cursorPos.y())],_usedColumns,_lineProperties[cursorPos.y()]);
        decoder.end();
        return lineText;
      }
      break;
    case Qt::ImCurrentSelection:
      return QString();
      break;
    default:
      break;
    }

  return QVariant();
}

void TerminalView::setBellMode(int mode)
{
  _bellMode=mode;
}

void TerminalView::enableBell()
{
  _allowBell = true;
}

void TerminalView::swapColorTable()
{
  ColorEntry color = _colorTable[1];
  _colorTable[1]=_colorTable[0];
  _colorTable[0]= color;
  _colorsInverted = !_colorsInverted;
  update();
}

void TerminalView::clearImage()
{
  // We initialize _image[_imageSize] too. See makeImage()
  for (int i = 0; i <= _imageSize; i++)
    {
      _image[i].character = ' ';
      _image[i].foregroundColor = CharacterColor(COLOR_SPACE_DEFAULT,
                                                 DEFAULT_FORE_COLOR);
      _image[i].backgroundColor = CharacterColor(COLOR_SPACE_DEFAULT,
                                                 DEFAULT_BACK_COLOR);
      _image[i].rendition = DEFAULT_RENDITION;
    }
}

void TerminalView::calcGeometry()
{
  _scrollBar->resize(QApplication::style()->pixelMetric(QStyle::PM_ScrollBarExtent),
                     contentsRect().height());
  switch(_scrollbarLocation)
    {
    case NoScrollBar :
      _leftMargin = DEFAULT_LEFT_MARGIN;
      _contentWidth = contentsRect().width() - 2 * DEFAULT_LEFT_MARGIN;
      break;
    case ScrollBarLeft :
      _leftMargin = DEFAULT_LEFT_MARGIN + _scrollBar->width();
      _contentWidth = contentsRect().width() - 2 * DEFAULT_LEFT_MARGIN - _scrollBar->width();
      _scrollBar->move(contentsRect().topLeft());
      break;
    case ScrollBarRight:
      _leftMargin = DEFAULT_LEFT_MARGIN;
      _contentWidth = contentsRect().width()  - 2 * DEFAULT_LEFT_MARGIN - _scrollBar->width();
      _scrollBar->move(contentsRect().topRight() - QPoint(_scrollBar->width()-1,0));
      break;
    }

  _topMargin = DEFAULT_TOP_MARGIN;
  _contentHeight = contentsRect().height() - 2 * DEFAULT_TOP_MARGIN + /* mysterious */ 1;

  if (!_isFixedSize)
    {
      // ensure that display is always at least one column wide
      _columns = qMax(1,qFloor(_contentWidth / _fontWidth));
      _usedColumns = qMin(_usedColumns,_columns);

      // ensure that display is always at least one line high
      _lines = qMax(1, qFloor(_contentHeight / _fontHeight));
      _usedLines = qMin(_usedLines,_lines);
    }
}

void TerminalView::makeImage()
{
  //qDebug("%s %d makeImage", __FILE__, __LINE__);
  calcGeometry();

  // confirm that array will be of non-zero size, since the painting code
  // assumes a non-zero array length
  Q_ASSERT( _lines > 0 && _columns > 0 );
  Q_ASSERT( _usedLines <= _lines && _usedColumns <= _columns );

  _imageSize=_lines*_columns;

  // We over-commit one character so that we can be more relaxed in dealing with
  // certain boundary conditions: _image[_imageSize] is a valid but unused position
  _image = new Character[_imageSize+1];

  clearImage();
}

// calculate the needed size
void TerminalView::setSize(int columns, int lines)
{
  //FIXME - Not quite correct, a small amount of additional space
  // will be used for margins, the scrollbar etc.
  // we need to allow for this so that '_size' does allow
  // enough room for the specified number of columns and lines to fit

  QSize newSize = QSize( columns * _fontWidth  ,
                         lines * _fontHeight   );

  if ( newSize != size() )
    {
      _size = newSize;
      updateGeometry();
    }
}

void TerminalView::setFixedSize(int cols, int lins)
{
  _isFixedSize = true;

  //ensure that display is at least one line by one column in size
  _columns = qMax(1,cols);
  _lines = qMax(1,lins);
  _usedColumns = qMin(_usedColumns,_columns);
  _usedLines = qMin(_usedLines,_lines);

  if (_image)
    {
      delete[] _image;
      makeImage();
    }
  setSize(cols, lins);
  QWidget::setFixedSize(_size);
}

QSize TerminalView::sizeHint() const
{
  return _size;
}


/* --------------------------------------------------------------------- */
/*                                                                       */
/* Drag & Drop                                                           */
/*                                                                       */
/* --------------------------------------------------------------------- */

void TerminalView::dragEnterEvent(QDragEnterEvent* event)
{
  if (event->mimeData()->hasFormat("text/plain"))
    event->acceptProposedAction();
}

void TerminalView::dropEvent(QDropEvent* event)
{
  //  KUrl::List urls = KUrl::List::fromMimeData(event->mimeData());

  QString dropText;

  if (event->mimeData ()->hasUrls ())
  {
    foreach (QUrl url, event->mimeData ()->urls ())
    {
      if(dropText.length () > 0)
        dropText += '\n';
      dropText  += url.toLocalFile ();
    }
  }

  /*  if (!urls.isEmpty())
  {
    for ( int i = 0 ; i < urls.count() ; i++ )
    {
        KUrl url = KIO::NetAccess::mostLocalUrl( urls[i] , 0 );
        QString urlText;

        if (url.isLocalFile())
            urlText = url.path();
        else
            urlText = url.url();

        // in future it may be useful to be able to insert file names with drag-and-drop
        // without quoting them (this only affects paths with spaces in)
        urlText = KShell::quoteArg(urlText);

        dropText += urlText;

        if ( i != urls.count()-1 )
            dropText += ' ';
    }
  }
  else
  {
    dropText = event->mimeData()->text();
  }
*/
  if(event->mimeData()->hasFormat("text/plain"))
    {
      emit sendStringToEmu(dropText.toLocal8Bit());
    }
}

void TerminalView::doDrag()
{
  dragInfo.state = diDragging;
  dragInfo.dragObject = new QDrag(this);
  QMimeData *mimeData = new QMimeData;
  mimeData->setText(QApplication::clipboard()->text(QClipboard::Selection));
  dragInfo.dragObject->setMimeData(mimeData);
  dragInfo.dragObject->exec(Qt::CopyAction);
  // Don't delete the QTextDrag object.  Qt will delete it when it's done with it.
}

void TerminalView::outputSuspended(bool suspended)
{
  //create the label when this function is first called
  if (!_outputSuspendedLabel)
    {
      //This label includes a link to an English language website
      //describing the 'flow control' (Xon/Xoff) feature found in almost
      //all terminal emulators.
      //If there isn't a suitable article available in the target language the link
      //can simply be removed.
      _outputSuspendedLabel = new QLabel( ("<qt>Output has been "
                                           "<a href=\"http://en.wikipedia.org/wiki/XON\">suspended</a>"
                                           " by pressing Ctrl+S."
                                           "  Press <b>Ctrl+Q</b> to resume.</qt>"),
                                          this );

      QPalette palette(_outputSuspendedLabel->palette());

      palette.setColor(QPalette::Normal, QPalette::WindowText, QColor(Qt::white));
      palette.setColor(QPalette::Normal, QPalette::Window, QColor(Qt::black));
      //            KColorScheme::adjustForeground(palette,KColorScheme::NeutralText);
      //		KColorScheme::adjustBackground(palette,KColorScheme::NeutralBackground);
      _outputSuspendedLabel->setPalette(palette);
      _outputSuspendedLabel->setAutoFillBackground(true);
      _outputSuspendedLabel->setBackgroundRole(QPalette::Base);
      _outputSuspendedLabel->setFont(QApplication::font());
      _outputSuspendedLabel->setMargin(5);

      //enable activation of "Xon/Xoff" link in label
      _outputSuspendedLabel->setTextInteractionFlags(Qt::LinksAccessibleByMouse |
                                                     Qt::LinksAccessibleByKeyboard);
      _outputSuspendedLabel->setOpenExternalLinks(true);
      _outputSuspendedLabel->setVisible(false);

      _gridLayout->addWidget(_outputSuspendedLabel);
      _gridLayout->addItem( new QSpacerItem(0,0,QSizePolicy::Expanding,
                                            QSizePolicy::Expanding),
                            1,0);

    }

  _outputSuspendedLabel->setVisible(suspended);
}

uint TerminalView::lineSpacing() const
{
  return _lineSpacing;
}

void TerminalView::setLineSpacing(uint i)
{
  _lineSpacing = i;
  setVTFont(font()); // Trigger an update.
}

QString TerminalView::selectedText ()
{
  QString text = _screenWindow->selectedText (_preserveLineBreaks);
  return text;
}

void
TerminalView::visibility_changed (bool visible)
{
  // Disable the timer for processing the filter chain, since this might time
  // consuming
  if (visible)
    _process_filter_timer->start (300);
  else
    _process_filter_timer->stop ();
}
