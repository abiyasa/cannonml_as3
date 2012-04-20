package mobi.papatong
{
	import flash.display.*;
	import flash.geom.*;
	import flash.filters.*;
	import flash.events.*;
	import flash.media.*;
	import flash.utils.*;
	
	/**
	 * LCD render
	 * @author Abiyasa
	 */
	public class LCDRender extends Bitmap
	{
		public var data:BitmapData = new BitmapData(96, 96, false, 0);
		public var charMap:Vector.<BitmapData> = Vector.<BitmapData>([
			hex2bmp("0000000000"), hex2bmp("00005f0000"), hex2bmp("0003000300"), hex2bmp("143e143e14"), //  !"#
			hex2bmp("242a7f2a12"), hex2bmp("4c2c106864"), hex2bmp("3649592650"), hex2bmp("0000030000"), // $%&'
			hex2bmp("001c224100"), hex2bmp("0041221c00"), hex2bmp("22143e1422"), hex2bmp("08083e0808"), // ()*+
			hex2bmp("0050300000"), hex2bmp("0808080808"), hex2bmp("0060600000"), hex2bmp("2010080402"), // ,-./
			hex2bmp("3e5149453e"), hex2bmp("00427f4000"), hex2bmp("4261514946"), hex2bmp("2241494936"), // 0123
			hex2bmp("3824227f20"), hex2bmp("4f49494931"), hex2bmp("3e49494932"), hex2bmp("0301710907"), // 4567
			hex2bmp("3649494936"), hex2bmp("264949493e"), hex2bmp("0036360000"), hex2bmp("0056360000"), // 89:;
			hex2bmp("0814224100"), hex2bmp("1414141414"), hex2bmp("0041221408"), hex2bmp("0201510906"), // <=>?
			hex2bmp("3e4159551e"), hex2bmp("7c2221227c"), hex2bmp("7f49494936"), hex2bmp("3e41414122"), // @ABC
			hex2bmp("7f4141423c"), hex2bmp("7f49494941"), hex2bmp("7f09090901"), hex2bmp("3e4149493a"), // DEFG
			hex2bmp("7f0808087f"), hex2bmp("00417f4100"), hex2bmp("2040413f01"), hex2bmp("7f08142241"), // HIJK
			hex2bmp("7f40404040"), hex2bmp("7f020c027f"), hex2bmp("7f0408107f"), hex2bmp("3e4141413e"), // LMNO
			hex2bmp("7f09090906"), hex2bmp("3e4151215e"), hex2bmp("7f09192946"), hex2bmp("2649494932"), // PQRS
			hex2bmp("01017f0101"), hex2bmp("3f4040403f"), hex2bmp("1f2040201f"), hex2bmp("1f601c601f"), // TUVW
			hex2bmp("6314081463"), hex2bmp("0708700807"), hex2bmp("6151494543"), hex2bmp("00007f4100"), // XYZ[
			hex2bmp("0204081020"), hex2bmp("00417f0000"), hex2bmp("0002010200"), hex2bmp("4040404040"), // \]^_
		]);
		
		private var _screen:BitmapData = new BitmapData(384, 384, true, 0);
		private var _display:BitmapData = new BitmapData(400, 400, false, 0);
		private var _cls:BitmapData = new BitmapData(400, 400, false, 0);
		private var _matS2D:Matrix = new Matrix(1,0,0,1,8,8);
		private var _shadow:DropShadowFilter = new DropShadowFilter(4, 45, 0, 0.6, 6, 6);
		private var _residueMap:Vector.<Number> = new Vector.<Number>(9216, true);
		private var _toneFilter:uint, _dotColor:uint, _residue:Number;
		private var _dot:Rectangle = new Rectangle(0,0,3,3);
		private var _pt:Point = new Point();
		private var _shape:Shape = new Shape();
		
		static public function hex2bmp(hex:String, height:int = 8, scale:int = 1) : BitmapData
		{
			var i:int, pat:int,
				rect:Rectangle = new Rectangle(0, 0, scale, scale),
				bmp:BitmapData = new BitmapData((hex.length>>1)*scale, height, true, 0);
			for (i=0, rect.x=0; i<hex.length; i+=2, rect.x+=scale)
				for (rect.y=0, pat=parseInt(hex.substr(i, 2), 16); pat!=0; rect.y+=scale, pat>>=1) {
					bmp.fillRect(rect, -(pat&1));
				}
			return bmp;
		}
		
		public function LCDRender(bit:int=2, backColor:uint = 0xb0c0b0,
						  dot0Color:uint = 0xb0b0b0, dot1Color:uint = 0x000000, residue:Number = 0.4)
		{
			_toneFilter = (0xff00 >> bit) & 0xff;
			_dotColor = dot1Color;
			_cls.fillRect(_cls.rect, backColor);
			_residue = residue;
			for (_dot.x=8; _dot.x<392; _dot.x+=4)
				for (_dot.y=8; _dot.y<392; _dot.y+=4)
					_cls.fillRect(_dot, dot0Color);
			charMap.length = 96;
			for (var i:int=32; i<64; i++) charMap[i+32] = charMap[i];
			super(_display);
			x = 32;
			y = 32;
		}
		
		public function cls() : void {
			data.fillRect(data.rect, 0);
		}
		
		public function line(x0:int, y0:int, x1:int, y1:int, color:int=255, thick:Number=1) : void {
			_shape.graphics.clear();
			_shape.graphics.lineStyle(thick, color);
			_shape.graphics.moveTo(x0, y0);
			_shape.graphics.lineTo(x1, y1);
			data.draw(_shape);
		}

		public function gprint(x:int, y:int, bmp:BitmapData) : void {
			_pt.x = x - (bmp.width >> 1);
			_pt.y = y - (bmp.height >> 1);
			data.copyPixels(bmp, bmp.rect, _pt);
		}
			
		public function print(x:int, y:int, str:String) : void {
			_pt.x = x;
			_pt.y = y;
			var bmp:BitmapData;
			for (var i:int=0; i<str.length; i++, _pt.x+=6) {
				bmp = charMap[str.charCodeAt(i)-32];
				data.copyPixels(bmp, bmp.rect, _pt);
			}
		}
		
		public function render() : void {
			var x:int, y:int, gray:int, mask:uint, i:int;
			_screen.fillRect(_screen.rect, 0);
			for (i=0, _dot.y=0, y=0; y<96; _dot.y+=4, y++) {
				for (_dot.x=0, x=0; x<96; _dot.x+=4, x++, i++) {
					gray = ((data.getPixel(x, y) & _toneFilter)>>1) + int(_residueMap[i]);
					if (gray > 255) gray = 255;
					_residueMap[i] = gray * _residue;
					if (gray) _screen.fillRect(_dot, (gray<<24) | _dotColor);
				}
			}
			_screen.applyFilter(_screen, _screen.rect, _screen.rect.topLeft, _shadow);
			_display.copyPixels(_cls, _cls.rect, _cls.rect.topLeft);
			_display.draw(_screen, _matS2D);
		}
	}

}