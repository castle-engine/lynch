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

{ Game initialization.
  This unit is cross-platform.
  It will be used by the platform-specific program or library file. }
unit GameInitialize;

interface

implementation

uses SysUtils, Classes,
  CastleWindow, CastleLog, CastleUIState, CastleSoundEngine, CastleComponentSerialize,
  CastleTimeUtils
  {$region 'Castle Initialization Uses'}
  // The content here may be automatically updated by CGE editor.
  , GameStateMenu
  , GameStatePlay
  {$endregion 'Castle Initialization Uses'};

var
  Window: TCastleWindow;

{ One-time initialization of resources. }
procedure ApplicationInitialize;
var
  Sounds: TComponent;
  SoundMusic: TCastleSound;
begin
  { Adjust container settings for a scalable UI (adjusts to any window size in a smart way). }
  Window.Container.LoadSettings('castle-data:/CastleSettings.xml');

  { Create game states and set initial state }
  {$region 'Castle State Creation'}
  // The content here may be automatically updated by CGE editor.
  StatePlay := TStatePlay.Create(Application);
  StateMenu := TStateMenu.Create(Application);
  {$endregion 'Castle State Creation'}

  TUIState.Current := StateMenu;

  Sounds := TComponent.Create(Application);
  ComponentLoad('castle-data:/sounds.castle-component', Sounds);
  SoundMusic := Sounds.FindRequiredComponent('SoundMusic') as TCastleSound;
  SoundEngine.LoopingChannel[0].Sound := SoundMusic;
end;

initialization
  { Initialize Application.OnInitialize. }
  Application.OnInitialize := @ApplicationInitialize;

  { Create and assign Application.MainWindow. }
  Window := TCastleWindow.Create(Application);
  Window.ParseParameters; // allows to control window size / fullscreen on the command-line
  Application.MainWindow := Window;

  { Adjust window fullscreen state and size.
    Note that some platforms (like mobile) may ignore it.
    Examples how to set window fullscreen state and size:

      Window.FullScreen := true;

    or

      Window.FullScreen := false; // default
      Window.Width := 600;
      Window.Height := 400;

    or

      Window.FullScreen := false; // default
      Window.Width := Application.ScreenWidth * 2 div 3;
      Window.Height := Application.ScreenHeight * 2 div 3;
  }

  { You should not need to do *anything* more in the unit "initialization" section.
    Most of your game initialization should happen inside ApplicationInitialize.
    In particular, it is not allowed to read files before ApplicationInitialize
    (because in case of non-desktop platforms,
    some necessary resources may not be prepared yet). }

  Profiler.Enabled := true;
end.
