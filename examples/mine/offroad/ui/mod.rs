use crate::global_state::GlobalState;

use bevy::prelude::*;

const COLOR_UI_BG: Srgba = bevy::color::palettes::css::WHITE;
const COLOR_UI_FG: Srgba = bevy::color::palettes::css::BLACK;
const COLOR_UI_HOOVER: Srgba = bevy::color::palettes::css::LIGHT_GRAY;
const COLOR_UI_PRESSED: Srgba = bevy::color::palettes::css::DARK_GRAY;

pub struct TrackSelectionPlugin;

impl Plugin for TrackSelectionPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(Startup, populate_track_menu);
        app.add_systems(Update, update_track_menu);
    }
}

fn populate_track_menu(mut commands: Commands) {
    commands.spawn(Camera2d::default());

    commands
        .spawn(Node {
            position_type: PositionType::Absolute,
            bottom: Val::Px(5.0),
            left: Val::Px(5.0),
            ..Node::default()
        })
        .with_children(|parent| {
            let mut add_button = |label: &str| -> () {
                parent
                    .spawn((
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

            add_button("Beginner");
            add_button("Vertical");
            add_button("Advanced");
        });
}

fn update_track_menu(
    query: Query<(&Interaction, &mut BackgroundColor), (Changed<Interaction>, With<Button>)>,
    mut next_state: ResMut<NextState<GlobalState>>,
) {
    for (interaction, mut bg_color) in query {
        match *interaction {
            Interaction::Pressed => {
                *bg_color = COLOR_UI_PRESSED.into();
            }
            Interaction::Hovered => {
                *bg_color = COLOR_UI_HOOVER.into();
                next_state.set(GlobalState::TrackSelectionHoover(0));
            }
            Interaction::None => {
                *bg_color = COLOR_UI_BG.into();
                next_state.set(GlobalState::TrackSelectionIdle);
            }
        }
    }
}
