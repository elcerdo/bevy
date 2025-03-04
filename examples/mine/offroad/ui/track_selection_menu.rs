use crate::global_state::{GlobalState, TrackNickname};
use crate::ui::consts::*;

use bevy::prelude::*;

pub struct TrackSelectionMenuPlugin;

impl Plugin for TrackSelectionMenuPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(
            OnEnter(GlobalState::InitDone),
            populate_track_selection_menu,
        );
        app.add_systems(
            OnEnter(GlobalState::TrackSelected(TrackNickname::Advanced)),
            depopulate_track_selection_menu,
        );
        app.add_systems(Update, update_track_selection_menu);
    }
}

#[derive(Component)]
struct TrackSelectionMenuMarker;

fn depopulate_track_selection_menu(
    mut commands: Commands,
    query: Query<Entity, With<TrackSelectionMenuMarker>>,
) {
    for entity in query {
        commands.entity(entity).despawn();
    }
}

fn populate_track_selection_menu(
    mut commands: Commands,
    mut next_state: ResMut<NextState<GlobalState>>,
) {
    commands.spawn((TrackSelectionMenuMarker, Camera2d::default()));

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
                next_state.set(GlobalState::TrackSelectionHoovered(*track));
            }
            Interaction::None => {
                *bg_color = COLOR_UI_BG.into();
                next_state.set(GlobalState::TrackSelectionIdle);
            }
        }
    }
}
