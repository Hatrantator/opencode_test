// @name Billboard
// @category Vertex
// @type Spatial
// @description

//MODELVIEW_MATRIX = yBillboardModelViewMatrix(VIEW_MATRIX,MAIN_CAM_INV_VIEW_MATRIX,MODEL_MATRIX);
//MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
mat4 yBillboardModelViewMatrix(mat4 view_matrix, mat4 main_cam_inv_view_matrix, mat4 model_matrix) {
	mat4 model_view_matrix = view_matrix * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), main_cam_inv_view_matrix[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(main_cam_inv_view_matrix[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			model_matrix[3]);
	return model_view_matrix;
}
