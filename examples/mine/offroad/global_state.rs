use bevy::prelude::*;

#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug, Default, States)]
pub enum GlobalState {
    #[default]
    Init,
    TrackSelectionIdle,
    TrackSelectionHoover(u8),
    InGame,
}

pub struct GlobalStatePlugin;

impl Plugin for GlobalStatePlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(OnEnter(GlobalState::Init), dump_init);
        app.add_systems(
            OnEnter(GlobalState::TrackSelectionIdle),
            dump_track_selection_idle,
        );
        app.add_systems(
            OnEnter(GlobalState::TrackSelectionHoover(0)),
            dump_track_selection_hoover,
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

fn dump_track_selection_idle() {
    info!("!!!! dump_track_selection_idle !!!!");
}

fn dump_track_selection_hoover() {
    info!("!!!! dump_track_selection_hoover !!!!");
}
