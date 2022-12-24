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

uses CastleBehaviors, CastleTransform, CastleCameras, CastleTimeUtils, CastleScene;

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

  { Rotate the statue (and make a sound) when it is *not seen* by player. }
  TStatueBehavior = class(TCastleBehavior)
  strict private
    Scene: TCastleScene;
    SoundSource: TCastleSoundSource;
  public
    procedure ParentAfterAttach; override;
    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;
  end;

implementation

uses Math, SysUtils,
  CastleVectors;

{ TFootstepsBehavior --------------------------------------------------------- }

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

{ TStatueBehavior ------------------------------------------------------------ }

procedure TStatueBehavior.ParentAfterAttach;
begin
  inherited;
  Scene := Parent as TCastleScene;
  SoundSource := Parent.FindBehavior(TCastleSoundSource) as TCastleSoundSource;
end;

procedure TStatueBehavior.Update(const SecondsPassed: Single; var RemoveMe: TRemoveType);
const
  RotationSpeed = 0.5; // radians / second
var
  Camera: TCastleCamera;
  DesiredDirection, NewDirection, Cross: TVector3;
  Angle: Single;
begin
  if not Scene.WasVisible then
  begin
    Camera := Parent.World.MainCamera;
    DesiredDirection := Camera.WorldTranslation - Scene.LocalToWorld(TVector3.Zero);
    MakeVectorsOrthoOnTheirPlane(DesiredDirection, Camera.GravityUp);
    DesiredDirection := DesiredDirection.Normalize;

    // Cross is either gravity up, or negation of it, or zero
    Cross := TVector3.CrossProduct(DesiredDirection, Parent.Direction);

    if not Cross.IsZero then
    begin
      Angle := RotationAngleRadBetweenVectors(DesiredDirection, Parent.Direction, Cross);

      { Angle values after correcting below are very small, so we judge whether
        to play SoundSource before correcting.
        Also, this makes it independent of SecondsPassed,
        so independent of system FPS. }
      SoundSource.SoundPlaying := Abs(Angle) > 0.01;

      if Angle > 0 then
        Angle := Min(Angle, RotationSpeed * SecondsPassed)
      else
        Angle := Max(Angle, -RotationSpeed * SecondsPassed);
      NewDirection := RotatePointAroundAxisRad(Angle, Parent.Direction, -Cross);

      Parent.Direction := NewDirection;
    end;

    //Parent.Direction := DesiredDirection; // this would make immediate rotation
  end else
    SoundSource.SoundPlaying := false;
end;

end.
