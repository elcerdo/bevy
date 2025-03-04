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
    Init,
    TrackSelectionIdle,
    TrackSelectionHoovered(TrackNickname),
    TrackSelected(TrackNickname),
    InGame,
}

pub struct GlobalStatePlugin;

impl Plugin for GlobalStatePlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(OnEnter(GlobalState::Init), dump_init);
        app.add_systems(OnEnter(GlobalState::TrackSelectionIdle), || {
            info!("!!!! idle !!!!");
        });
        app.add_systems(
            OnEnter(GlobalState::TrackSelectionHoovered(TrackNickname::Beginner)),
            || {
                info!("!!!! hoover_beginner !!!!");
            },
        );
        app.add_systems(
            OnEnter(GlobalState::TrackSelected(TrackNickname::Advanced)),
            || {
                info!("!!!! selected_advanced !!!!");
            },
        );
        app.init_state::<GlobalState>();
    }
    fn finish(&self, app: &mut App) {
        app.insert_state(GlobalState::TrackSelectionIdle);
    }
}

fn dump_init() {
    info!("!!!! dump_init !!!!");
}
