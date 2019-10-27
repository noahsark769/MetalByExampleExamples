//
//  ChapterTwoShaders.metal
//  MetalByExampleExamples
//
//  Created by Noah Gilmore on 10/27/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ChapterTwoVertexInOut {
    /// Position of the vertex
    float4 position [[position]];

    /// Color of the vertex
    float4 color;
};

vertex ChapterTwoVertexInOut chapter_two_vertex_shader(device ChapterTwoVertexInOut *vertices [[buffer(0)]],
                                                       uint vertexId [[vertex_id]])
{
    return vertices[vertexId];
}

fragment float4 chapter_two_fragment_shader(ChapterTwoVertexInOut inVertex [[stage_in]]) {
    return inVertex.color;
}
