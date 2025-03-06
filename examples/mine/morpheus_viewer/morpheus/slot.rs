use bevy::asset::weak_handle;
use bevy::render::render_resource::ShaderRef;

use bevy::prelude::*;

pub trait Slot: TypePath + Clone + Sync + Send {
    const RAY_HANDLE: Handle<Shader>;
    fn raymarching_shader() -> ShaderRef {
        Self::RAY_HANDLE.into()
    }
}

// #[derive(Clone, TypePath)]
// struct SdfSlot<const NN: usize>;

// impl<const NN: usize> Sdf for SdfSlot<NN> {
//     const RAY_HANDLE: Handle<Shader> = match NN {
//         0 => weak_handle!("7987c9b7-1598-0000-0000-023a354b7cac"),
//         1 => weak_handle!("7987c9b7-1598-0000-0001-023a354b7cac"),
//         2 => weak_handle!("7987c9b7-1598-0000-0002-023a354b7cac"),
//         3 => weak_handle!("7987c9b7-1598-0000-0003-023a354b7cac"),
//         _ => unreachable!(),
//     };
// }
// pub type Slot0 = SdfSlot<0>;
// pub type Slot1 = SdfSlot<1>;
// pub type Slot2 = SdfSlot<2>;
// pub type Slot3 = SdfSlot<3>;

#[derive(Clone, TypePath)]
pub struct Slot0;

impl Slot for Slot0 {
    const RAY_HANDLE: Handle<Shader> = weak_handle!("7987c9b7-c46a-0000-1111-023a354b7cac");
}

#[derive(Clone, TypePath)]
pub struct Slot1;

impl Slot for Slot1 {
    const RAY_HANDLE: Handle<Shader> = weak_handle!("7987c9b7-c46a-1111-1111-023a354b7cac");
}

#[derive(Clone, TypePath)]
pub struct Slot2;

impl Slot for Slot2 {
    const RAY_HANDLE: Handle<Shader> = weak_handle!("7987c9b7-c46a-2222-1111-023a354b7cac");
}

#[derive(Clone, TypePath)]
pub struct Slot3;

impl Slot for Slot3 {
    const RAY_HANDLE: Handle<Shader> = weak_handle!("7987c9b7-c46a-3333-1111-023a354b7cac");
}
