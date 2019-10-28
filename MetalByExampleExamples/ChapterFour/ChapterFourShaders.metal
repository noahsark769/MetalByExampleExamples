//
//  ChapterFourShaders.metal
//  MetalByExampleExamples
//
//  Created by Noah Gilmore on 10/27/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ChapterFourVertexInOut {
    /// Position of the vertex
    float4 position [[position]];

    /// Color of the vertex
    float4 color;
};

struct ChapterFourUniforms {
    float4x4 modelViewProjection;
};

vertex ChapterFourVertexInOut chapter_four_vertex_shader(device ChapterFourVertexInOut *vertices [[buffer(0)]],
                                                          constant ChapterFourUniforms *uniforms [[buffer(1)]],
                                                          uint vertexId [[vertex_id]])
{
    ChapterFourVertexInOut out;
    out.color = vertices[vertexId].color;
    out.position = uniforms->modelViewProjection * vertices[vertexId].position;
    return out;
}

fragment float4 chapter_four_fragment_shader(ChapterFourVertexInOut inVertex [[stage_in]]) {
    return inVertex.color;
}


