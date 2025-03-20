use bevy::prelude::*;
use bevy::render::render_resource::{AsBindGroup, ShaderRef};

pub const SHADER_PATH: &str = "shaders/wgpu_reduce/debug.wgsl";

#[derive(Asset, TypePath, AsBindGroup, Clone)]
pub struct DebugMaterial {
    // #[texture(0)]
    // #[sampler(1)]
    // pub pattern_texture: Option<Handle<Image>>,
    // #[texture(2)]
    // #[sampler(3)]
    // pub warp_texture: Option<Handle<Image>>,
    // #[uniform(4)]
    // pub warp_amount: f32,
}

impl Material for DebugMaterial {
    fn fragment_shader() -> ShaderRef {
        SHADER_PATH.into()
    }

    fn alpha_mode(&self) -> AlphaMode {
        AlphaMode::Blend
    }
}

// impl DebugMaterial {
//     pub fn new(pattern_texture: Handle<Image>, warp_texture: Handle<Image>) -> Self {
//         Self {
//             pattern_texture: Some(pattern_texture),
//             warp_texture: Some(warp_texture),
//             warp_amount: 1.0,
//         }
//     }
// }
