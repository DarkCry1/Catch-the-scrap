"""Static UI layout review, not a Roblox Studio screenshot. No source images used."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1]
img=Image.new('RGB',(1200,660),(10,18,27));draw=ImageDraw.Draw(img)
fontdir=Path('/usr/share/fonts/truetype/dejavu')
def font(size,bold=False):return ImageFont.truetype(str(fontdir/('DejaVuSans-Bold.ttf' if bold else 'DejaVuSans.ttf')),size)
def text(x,y,value,size=15,color=(225,237,244),bold=False):draw.text((x,y),value,font=font(size,bold),fill=color)
def card(box):draw.rounded_rectangle(box,14,fill=(18,29,40),outline=(59,82,100),width=1)
def button(box,value):
 draw.rounded_rectangle(box,8,fill=(36,53,68));b=draw.textbbox((0,0),value,font=font(11,True));draw.text(((box[0]+box[2]-(b[2]-b[0]))/2,(box[1]+box[3]-13)/2),value,font=font(11,True),fill=(225,237,244))
text(38,24,'CATCH THE SCRAP / COMPACT HUD',25,bold=True)
text(40,62,'Layout review — Roblox fonts and rendering differ in Studio.',13,color=(151,177,194))
text(40,113,'ALWAYS VISIBLE',12,color=(255,196,88),bold=True)
card((40,144,284,226));text(54,150,'$1.2K',28,(112,240,182),True);text(55,192,'+$5 / SEC',13,(160,187,201));button((204,156,272,182),'BASE 01');button((204,190,272,213),'DETAILS')
text(40,258,'ONE CURRENT GOAL',12,(255,196,88),True)
card((40,288,440,358));text(54,297,'Common robot  1 / 5',15,bold=True);text(54,324,'Collect matching scrap in this area.',12,(165,191,206));draw.rectangle((54,351,426,353),fill=(51,74,87));draw.rectangle((54,351,128,353),fill=(255,193,76))
text(40,392,'WHILE CARRYING',12,(255,196,88),True)
card((40,422,440,492));text(54,431,'Common Gear',15,bold=True);text(54,458,'Deliver to Base 01',12,(165,191,206));button((344,438,428,474),'DROP [Q]');draw.rectangle((54,485,426,487),fill=(255,193,76))
text(40,544,'The empty-hands message, permanent title and seven recipe rows',13,(151,177,194));text(40,566,'no longer cover the playfield. Details open only when requested.',13,(151,177,194))
text(520,113,'DETAILS / ON DEMAND',12,(255,196,88),True)
card((520,144,810,474));text(534,154,'YOUR WORKSHOP',15,bold=True);button((768,153,796,179),'X');text(534,186,'Robots: 1/4  |  Speed: 24',12);text(534,203,'Strength: 30  |  Carrying: 0 weight',12)
tiers=[('Common',5,5),('Uncommon',7,10),('Rare',10,20),('Epic',12,45),('Legendary',15,100),('Mythic',18,225),('Celestial',20,500)]
for i,(tier,parts,income) in enumerate(tiers):text(534,226+i*22,f'{tier}  0 / {parts}   ${income}/sec',12,(175,208,224))
text(534,388,'CARRY METHOD',11)
for i,label in enumerate(('AUTO','HANDHELD','HARNESS')):button((534+i*89,411,616+i*89,439),label)
text(534,449,'Progress lasts for this server visit.',10,(143,166,181))
text(855,154,'CARRY CHOICES',14,(255,196,88),True)
text(855,193,'Auto',15,bold=True);text(855,220,'Native two-hand IK',12);text(855,241,'or standard Tool hold.',12)
text(855,290,'Handheld',15,bold=True);text(855,317,'Standard Roblox Tool.',12)
text(855,366,'Harness',15,bold=True);text(855,393,'Cargo secured to the back.',12)
text(520,544,'Admin controls: F4 / ADMIN',14,(112,240,182),True);text(520,570,'Cash · Speed · Strength · Events · Return to base',12,(151,177,194))
(ROOT/'build').mkdir(exist_ok=True);img.save(ROOT/'build/hud-layout-v0.9.png')
