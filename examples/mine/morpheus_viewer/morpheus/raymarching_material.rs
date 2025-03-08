use crate::morpheus::slot::Slot;

use bevy::prelude::*;
use bevy::render::render_resource::{AsBindGroup, ShaderRef};

use std::marker::PhantomData;

#[derive(Asset, TypePath, AsBindGroup, Clone)]
pub struct MorpheusRaymarchingMaterial<S: Slot> {
    #[texture(0)]
    #[sampler(1)]
    pub matcap_texture: Option<Handle<Image>>,
    #[uniform(2)]
    pub bbox_center: Vec3,
    phantom: PhantomData<S>,
}

impl<S: Slot> Material for MorpheusRaymarchingMaterial<S> {
    fn vertex_shader() -> ShaderRef {
        S::raymarching_shader()
    }

    fn fragment_shader() -> ShaderRef {
        S::raymarching_shader()
    }

    fn alpha_mode(&self) -> AlphaMode {
        AlphaMode::Blend
    }
}

impl<S: Slot> MorpheusRaymarchingMaterial<S> {
    pub fn new(matcap_texture: Handle<Image>) -> Self {
        Self {
            bbox_center: Vec3::ZERO,
            matcap_texture: Some(matcap_texture),
            phantom: PhantomData,
        }
    }
}
