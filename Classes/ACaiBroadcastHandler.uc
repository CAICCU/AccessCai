class ACaiBroadcastHandler extends BroadcastHandler;

var AccessCai AC;

function InitACaiClass(AccessCai NewAC) {
	AC = NewAC;
}

function BroadcastText( PlayerReplicationInfo SenderPRI, PlayerController Receiver, coerce string Msg, optional name Type ) {
	if (AC!=None) {
		if (SenderPRI!=None) {
			if (PlayerController(SenderPRI.Owner)==Receiver) {
				AC.Broadcast(SenderPRI,Msg);
			}
		}
	}
	if (AC.StopBroadcast(Msg)) return;
	super.BroadcastText(SenderPRI,Receiver,Msg,Type);
}