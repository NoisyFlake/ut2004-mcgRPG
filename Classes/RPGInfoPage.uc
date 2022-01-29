//Shows rpg info
class RPGInfoPage extends RPGMenuBase;

var() automated GUIScrollTextBox MyScrollText;
var() automated GUIButton CloseButton;

function bool CloseClick(GUIComponent Sender)
{
	Controller.CloseMenu(false);
	return true;
}

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);
    MyScrollText.MyScrollText.OnKeyEvent = InternalOnKeyEvent;
}

defaultproperties
{
     Begin Object Class=GUIScrollTextBox Name=InfoText
         bNoTeletype=True
         CharDelay=0.002500
         EOLDelay=0.002500
         OnCreateComponent=InfoText.InternalOnCreateComponent
         WinTop=0.300000
         WinLeft=0.210000
         WinWidth=0.580000
         WinHeight=0.390000
         bNeverFocus=True
         OnKeyEvent=RPGInfoPage.InternalOnKeyEvent
     End Object
     MyScrollText=GUIScrollTextBox'mcgRPG1_9_9_1.RPGInfoPage.InfoText'

     Begin Object Class=GUIButton Name=ButtonClose
         Caption="Close"
         WinTop=0.700000
         WinLeft=0.400000
         WinWidth=0.200000
         OnClick=RPGInfoPage.CloseClick
         OnRightClick=RPGInfoPage.CloseClick
         OnKeyEvent=RPGInfoPage.InternalOnKeyEvent
     End Object
     CloseButton=GUIButton'mcgRPG1_9_9_1.RPGInfoPage.ButtonClose'

     WindowName="RPG Info"
}
