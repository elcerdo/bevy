use crate::global_state::{GlobalState, TrackNickname};
use crate::track::{Track, TRACK_HANDLES};
use crate::ui::consts::*;

use bevy::asset::Handle;
use bevy::prelude::*;

use bevy::color::palettes::css::GRAY;
use std::f32::consts::PI;

pub struct TrackSelectionMenuPlugin;

impl Plugin for TrackSelectionMenuPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(OnEnter(GlobalState::TrackSelectionInit), populate_scene);

        for state in [
            GlobalState::TrackSelectionHoovered(TrackNickname::Beginner),
            GlobalState::TrackSelectionHoovered(TrackNickname::Vertical),
            GlobalState::TrackSelectionHoovered(TrackNickname::Advanced),
        ] {
            app.add_systems(OnEnter(state), update_selected_model);
            app.add_systems(Update, animate_selected_model.run_if(in_state(state)));
        }

        app.add_systems(
            OnEnter(GlobalState::TrackSelected(TrackNickname::Advanced)),
            depopulate_all,
        );

        app.add_systems(Update, update_menu);
    }
}

#[derive(Component)]
struct TrackSelectionModelMarker;

fn update_selected_model(
    mut commands: Commands,
    entities: Query<Entity, With<TrackSelectionModelMarker>>,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    tracks: Res<Assets<Track>>,
    state: Res<State<GlobalState>>,
) {
    for entity in entities {
        commands.entity(entity).despawn();
    }

    let mesh_handle: Handle<Mesh> = match state.get() {
        GlobalState::TrackSelectionHoovered(TrackNickname::Beginner) => {
            let track = tracks.get(&TRACK_HANDLES[0]).unwrap();
            meshes.add(track.track.clone())
        }
        GlobalState::TrackSelectionHoovered(TrackNickname::Vertical) => {
            let track = tracks.get(&TRACK_HANDLES[1]).unwrap();
            meshes.add(track.track.clone())
        }
        GlobalState::TrackSelectionHoovered(TrackNickname::Advanced) => {
            let track = tracks.get(&TRACK_HANDLES[2]).unwrap();
            meshes.add(track.track.clone())
        }
        _ => unreachable!(),
    };

    commands.spawn((
        TrackSelectionModelMarker,
        Mesh3d(mesh_handle),
        MeshMaterial3d(materials.add(StandardMaterial {
            base_color: Color::from(GRAY),
            ..StandardMaterial::default()
        })),
    ));
}

fn animate_selected_model(
    query: Query<&mut Transform, With<TrackSelectionModelMarker>>,
    time: Res<Time>,
) {
    for mut transform in query {
        transform.rotation *= Quat::from_axis_angle(Vec3::Y, 0.5 * PI * time.delta_secs());
    }
}

#[derive(Component)]
struct TrackSelectionSceneMarker;

fn populate_scene(mut commands: Commands, mut next_state: ResMut<NextState<GlobalState>>) {
    use bevy::prelude::*;

    // light
    commands.spawn((
        TrackSelectionSceneMarker,
        DirectionalLight {
            color: Color::WHITE,
            shadows_enabled: true,
            illuminance: light_consts::lux::OVERCAST_DAY,
            ..default()
        },
        Transform::from_translation(Vec3::Y).looking_at(vec3(-1.0, 0.0, -1.0), Vec3::Y),
    ));

    // camera
    commands.spawn((
        TrackSelectionSceneMarker,
        Camera3d::default(),
        Transform::from_xyz(-10.0, 10.0, 15.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));

    // ui buttons
    commands
        .spawn((
            TrackSelectionSceneMarker,
            Node {
                position_type: PositionType::Absolute,
                bottom: Val::Px(5.0),
                left: Val::Px(5.0),
                ..Node::default()
            },
        ))
        .with_children(|parent| {
            let mut add_button = |track_nickname: TrackNickname| -> () {
                parent
                    .spawn((
                        track_nickname,
                        Button,
                        Node {
                            width: Val::Px(170.0),
                            height: Val::Px(60.0),
                            border: UiRect::all(Val::Px(5.0)),
                            margin: UiRect::right(Val::Px(5.0)),
                            justify_content: JustifyContent::Center,
                            align_items: AlignItems::Center,
                            ..default()
                        },
                        BorderColor(COLOR_UI_FG.into()),
                        BorderRadius::MAX,
                        BackgroundColor(COLOR_UI_BG.into()),
                    ))
                    .with_child((
                        Text::new(format!("{:?}", track_nickname)),
                        TextFont {
                            font_size: 25.0,
                            ..TextFont::default()
                        },
                        TextColor(COLOR_UI_FG.into()),
                    ));
            };

            add_button(TrackNickname::Beginner);
            add_button(TrackNickname::Vertical);
            add_button(TrackNickname::Advanced);
        });

    next_state.set(GlobalState::TrackSelectionIdle);
}

fn update_menu(
    query: Query<
        (&Interaction, &TrackNickname, &mut BackgroundColor),
        (Changed<Interaction>, With<Button>),
    >,
    mut next_state: ResMut<NextState<GlobalState>>,
) {
    for (interaction, track, mut bg_color) in query {
        match *interaction {
            Interaction::Pressed => {
                *bg_color = COLOR_UI_PRESSED.into();
                next_state.set(GlobalState::TrackSelected(*track));
            }
            Interaction::Hovered => {
                *bg_color = COLOR_UI_HOOVER.into();
                next_state.set(GlobalState::TrackSelectionHoovered(*track));
            }
            Interaction::None => {
                *bg_color = COLOR_UI_BG.into();
                next_state.set(GlobalState::TrackSelectionIdle);
            }
        }
    }
}

fn depopulate_all(
    mut commands: Commands,
    entities_aa: Query<Entity, With<TrackSelectionModelMarker>>,
    entities_bb: Query<Entity, With<TrackSelectionSceneMarker>>,
) {
    for entity in entities_aa {
        commands.entity(entity).despawn();
    }
    for entity in entities_bb {
        commands.entity(entity).despawn();
    }
}
