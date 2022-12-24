{
  Copyright 2022-2022 Michalis Kamburelis.

  This file is part of "Lynch".

  "Lynch" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Lynch" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Behaviors (TCastleBehaviors) attached to game objects. }
unit GameBehaviors;

interface

uses CastleBehaviors, CastleTransform, CastleCameras, CastleTimeUtils;

type
  { Play footsteps sound, when we're walking.
    This simply observes Navigation.IsWalkingOnTheGround,
    and controls the playback of FootstepsSoundSource
    (which is TCastleSoundSource found on parent). }
  TFootstepsBehavior = class(TCastleBehavior)
  strict private
    FootstepsSoundSource: TCastleSoundSource;

    { To avoid starting/stopping sound often when Navigation.IsWalkingOnTheGround
      changes too abruptly, we only schedule sound stop, instead of doing
      it immediately. (But we still start it immediately.)

      StopAfterTime is non-zero if some change is scheduled now,
      and determines how many seconds need to pass for the change to happen. }
    StopAfterTime: TFloatTime;
  public
    { Navigation to observe.
      Set it right after creation, cannot remain @nil for Update. }
    Navigation: TCastleWalkNavigation;
    procedure ParentAfterAttach; override;
    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;
  end;

implementation

procedure TFootstepsBehavior.ParentAfterAttach;
begin
  inherited;
  FootstepsSoundSource := Parent.FindBehavior(TCastleSoundSource) as TCastleSoundSource;
end;

procedure TFootstepsBehavior.Update(const SecondsPassed: Single; var RemoveMe: TRemoveType);
const
  DefaultStopAfterTime = 0.25;
begin
  inherited;

  { This simple implementation would just change FootstepsSoundSource.SoundPlaying
    immediately. }
  // FootstepsSoundSource.SoundPlaying := Navigation.IsWalkingOnTheGround;

  { Change FootstepsSoundSource.SoundPlaying.
    But do not change it to false immediately, only schedule such change. }
  if FootstepsSoundSource.SoundPlaying and not Navigation.IsWalkingOnTheGround then
  begin
    { schedule stop, unless it is already scheduled }
    if StopAfterTime = 0 then
      StopAfterTime := DefaultStopAfterTime;
  end else
  begin
    FootstepsSoundSource.SoundPlaying := Navigation.IsWalkingOnTheGround;
    StopAfterTime := 0; // no stop scheduled
  end;

  { Apply StopAfterTime, maybe stopping sound now. }
  if StopAfterTime <> 0 then
  begin
    StopAfterTime := StopAfterTime - SecondsPassed;
    if StopAfterTime <= 0 then
    begin
      StopAfterTime := 0;
      FootstepsSoundSource.SoundPlaying := false;
    end;
  end;
end;

end.
