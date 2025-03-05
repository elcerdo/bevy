use crate::global_state::{GlobalState, TrackNickname};
use crate::track::{Track, TRACK_CURRENT_HANDLE};
use crate::ui::consts::*;

use bevy::color::palettes::css::GRAY;
use bevy::prelude::*;
use std::f32::consts::PI;

pub struct TrackSelectionMenuPlugin;

impl Plugin for TrackSelectionMenuPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(OnEnter(GlobalState::TrackSelectionInit), populate_scene);
        app.add_systems(
            OnEnter(GlobalState::TrackSelectionIdle),
            update_selected_model,
        );
        app.add_systems(
            OnEnter(GlobalState::TrackSelectionHoovered(TrackNickname::Beginner)),
            update_selected_model,
        );
        app.add_systems(
            OnEnter(GlobalState::TrackSelectionHoovered(TrackNickname::Vertical)),
            update_selected_model,
        );
        app.add_systems(
            OnEnter(GlobalState::TrackSelectionHoovered(TrackNickname::Advanced)),
            update_selected_model,
        );

        app.add_systems(
            OnEnter(GlobalState::TrackSelected(TrackNickname::Advanced)),
            depopulate_all,
        );
        app.add_systems(
            Update,
            animate_selected_model.run_if(in_state(GlobalState::TrackSelectionHoovered(
                TrackNickname::Advanced,
            ))),
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
            let track = tracks.get(&TRACK_CURRENT_HANDLE).unwrap();
            meshes.add(track.track.clone())
        }
        _ => meshes.add(Cuboid::from_length(2.0)),
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
        transform.rotation *= Quat::from_axis_angle(Vec3::Y, 2.0 * PI * time.delta_secs());
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
            let mut add_button = |label: &str, track: TrackNickname| -> () {
                parent
                    .spawn((
                        track,
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
                        Text::new(label),
                        TextFont {
                            font_size: 25.0,
                            ..TextFont::default()
                        },
                        TextColor(COLOR_UI_FG.into()),
                    ));
            };

            add_button("Beginner", TrackNickname::Beginner);
            add_button("Vertical", TrackNickname::Vertical);
            add_button("Advanced", TrackNickname::Advanced);
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
