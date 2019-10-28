//
//  ChapterFourShaderTypes.h
//  MetalByExampleExamples
//
//  Created by Noah Gilmore on 10/27/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

#ifndef ChapterFourShaderTypes_h
#define ChapterFourShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef struct {
    /// Position of the vertex
    vector_float4 position;

    /// Color of the vertex
    vector_float4 color;
} ChapterFourVertexInOut;

typedef struct {
    /// Transforms from model space to view space
    matrix_float4x4 modelViewProjection;
} ChapterFourUniforms;

#endif /* ChapterFourShaderTypes_h */
