use bevy::prelude::*;

#[derive(Component, Clone, Debug, Copy, PartialEq, Eq, Hash)]
pub enum TrackNickname {
    Beginner,
    Vertical,
    Advanced,
}

#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug, Default, States)]
pub enum GlobalState {
    #[default]
    InitStarted,
    InitDone,
    TrackSelectionIdle,
    TrackSelectionHoovered,
    TrackSelected(TrackNickname),
    InGame,
    GameDone,
}

pub struct GlobalStatePlugin;

impl Plugin for GlobalStatePlugin {
    fn build(&self, app: &mut App) {
        app.init_state::<GlobalState>();
        app.add_systems(OnEnter(GlobalState::InitDone), || {
            info!("!!!! InitDone !!!!");
        });
        app.add_systems(OnEnter(GlobalState::TrackSelectionIdle), || {
            info!("!!!! TrackSelectionIdle !!!!");
        });
        app.add_systems(OnEnter(GlobalState::TrackSelectionHoovered), || {
            info!("!!!! TrackSelectionHoovered !!!!");
        });
        app.add_systems(
            OnEnter(GlobalState::TrackSelected(TrackNickname::Advanced)),
            || {
                info!("!!!! TrackSelected(Advanced) !!!!");
            },
        );
        app.add_systems(OnEnter(GlobalState::InGame), || {
            info!("!!!! InGame !!!!");
        });
        app.add_systems(OnEnter(GlobalState::GameDone), || {
            info!("!!!! GameDone !!!!");
        });
    }
    fn finish(&self, app: &mut App) {
        app.insert_state(GlobalState::InitDone);
    }
}
