class UnionServerSync extends TcpLink;
 
var string TargetHost; //URL or P address of web server
var int TargetPort; //port you want to use for the link
var string path; //path to file you want to request
var string params;

event PostBeginPlay()
{
    super.PostBeginPlay();
}
function startSync()
{
    Resolve(TargetHost);
}
event Resolved( IpAddr Addr )
{
    Addr.Port = TargetPort;
    `Log("[UAC] Bound to port: "$BindPort());
    if (!Open(Addr))
    {
        `Log("[UAC] Failed to push server information...");
    }
}
event ResolveFailed()
{
    `Log("[UAC] Unable to push server information...");
}
event Opened()
{
    local string sendStr;

    sendStr = "GET /"$params$" HTTP/1.1"
    $chr(13)$chr(10)
    $"Host: "$TargetHost
    $chr(13)$chr(10)
    $"Connection: Close"
    $chr(13)$chr(10)$chr(13)$chr(10);

    SendText(sendStr);
}
event ReceivedText( string Text )
{
    local int idx;
    local string split;

    split = ""$chr(13)$chr(10)$chr(13)$chr(10);
    idx = InStr(Text, split);

    if (Idx != -1)
    {
        Text = Mid(Text,Idx+4, Len(Text));
        `Log("[UAC] "$Text);
    }
}