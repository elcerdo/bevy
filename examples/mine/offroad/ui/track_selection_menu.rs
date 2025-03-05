use crate::global_state::{GlobalState, TrackNickname};
use crate::ui::consts::*;

use bevy::color::palettes::css::GRAY;
use bevy::prelude::*;
use std::f32::consts::PI;

pub struct TrackSelectionMenuPlugin;

impl Plugin for TrackSelectionMenuPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(OnEnter(GlobalState::InitDone), populate);
        app.add_systems(
            OnEnter(GlobalState::TrackSelected(TrackNickname::Advanced)),
            depopulate,
        );
        app.add_systems(Update, update_track_selection_menu);
        app.add_systems(
            Update,
            animate_selected_model.run_if(in_state(GlobalState::TrackSelectionHoovered)),
        );
    }
}

#[derive(Component)]
struct TrackSelectionMenuMarker;

#[derive(Component)]
struct TrackSelectionModelMarker;

fn populate(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    mut next_state: ResMut<NextState<GlobalState>>,
) {
    use bevy::prelude::*;

    // light
    commands.spawn((
        TrackSelectionMenuMarker,
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
        TrackSelectionMenuMarker,
        Camera3d::default(),
        Transform::from_xyz(-10.0, 10.0, 15.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));

    // cube
    commands.spawn((
        TrackSelectionMenuMarker,
        TrackSelectionModelMarker,
        Mesh3d(meshes.add(Cuboid::from_length(2.0))),
        MeshMaterial3d(materials.add(StandardMaterial {
            base_color: Color::from(GRAY),
            ..StandardMaterial::default()
        })),
    ));

    // ui buttons
    commands
        .spawn((
            TrackSelectionMenuMarker,
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

fn animate_selected_model(
    query: Query<&mut Transform, With<TrackSelectionModelMarker>>,
    time: Res<Time>,
) {
    for mut transform in query {
        transform.rotation *= Quat::from_axis_angle(Vec3::Y, 2.0 * PI * time.delta_secs());
    }
}

fn update_track_selection_menu(
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
                next_state.set(GlobalState::TrackSelectionHoovered);
            }
            Interaction::None => {
                *bg_color = COLOR_UI_BG.into();
                next_state.set(GlobalState::TrackSelectionIdle);
            }
        }
    }
}

fn depopulate(mut commands: Commands, query: Query<Entity, With<TrackSelectionMenuMarker>>) {
    for entity in query {
        commands.entity(entity).despawn();
    }
}
