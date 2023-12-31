class AccessMutator extends KFMutator;

var AccessCai AccessController;

function PostBeginPlay()
{
	if( WorldInfo.Game.BaseMutator==None )
		WorldInfo.Game.BaseMutator = Self;
	else WorldInfo.Game.BaseMutator.AddMutator(Self);

}

function AddMutator(Mutator M)
{
	if( M!=Self ) // Make sure we don't get added twice.
	{
		if( M.Class==Class )
			M.Destroy();
		else Super.AddMutator(M);
	}
}



function NotifyLogin(Controller NewPlayer)
{
	if( AccessController!=None && PlayerController(NewPlayer)!=None )
		AccessController.CheckMutedPlayers(PlayerController(NewPlayer));
	if ( NextMutator != None )
		NextMutator.NotifyLogin(NewPlayer);
			
}

defaultproperties
{
}