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

{ Main "playing game" state, where most of the game logic takes place. }
unit GameStatePlay;

interface

uses Classes,
  CastleUIState, CastleComponentSerialize, CastleUIControls, CastleControls,
  CastleKeysMouse, CastleViewport, CastleScene, CastleVectors, CastleCameras,
  CastleTransform;

type
  { Main "playing game" state, where most of the game logic takes place. }
  TStatePlay = class(TUIState)
  published
    { Components designed using CGE editor.
      These fields will be automatically initialized at Start. }
    LabelFps: TCastleLabel;
    MainViewport: TCastleViewport;
    WalkNavigation: TCastleWalkNavigation;
    PlayerCamera: TCastleCamera;
    LabelMouseLookHint: TCastleLabel;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Stop; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: Boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;
  end;

var
  StatePlay: TStatePlay;

implementation

uses SysUtils, Math,
  CastleSoundEngine, CastleLog, CastleStringUtils, CastleFilesUtils,
  GameStateMenu, GameBehaviors;

{ TStatePlay ----------------------------------------------------------------- }

constructor TStatePlay.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gamestateplay.castle-user-interface';
end;

procedure TStatePlay.Start;
var
  Footsteps: TFootstepsBehavior;
  I: Integer;
  SceneStatue: TCastleScene;
begin
  inherited;

  Footsteps := TFootstepsBehavior.Create(FreeAtStop);
  Footsteps.Navigation := WalkNavigation;
  PlayerCamera.AddBehavior(Footsteps);

  for I := 1 to 7 do
  begin
    SceneStatue := DesignedComponent('SceneStatue' + IntToStr(I)) as TCastleScene;
    SceneStatue.AddBehavior(TStatueBehavior.Create(FreeAtStop));
  end;

  { TODO: This still causes some initial rotation, even with MouseLookIgnoreNextMotion
  Container.MouseLookIgnoreNextMotion; // otherwise mouse motion during loading would rotate initial view
  WalkNavigation.MouseLook := true;
  }
end;

procedure TStatePlay.Stop;
begin
  inherited;
end;

procedure TStatePlay.Update(const SecondsPassed: Single; var HandleInput: Boolean);
begin
  inherited;
  LabelFps.Caption := 'FPS: ' + Container.Fps.ToString;
  LabelMouseLookHint.Exists := not WalkNavigation.MouseLook;
end;

function TStatePlay.Press(const Event: TInputPressRelease): Boolean;
begin
  Result := inherited;
  if Result then Exit; // allow the ancestor to handle keys

  if Event.IsMouseButton(buttonRight) then
  begin
    WalkNavigation.MouseLook := not WalkNavigation.MouseLook;
    Exit(true);
  end;

  if Event.IsKey(keyF5) then
  begin
    Container.SaveScreenToDefaultFile;
    Exit(true);
  end;
end;

end.
