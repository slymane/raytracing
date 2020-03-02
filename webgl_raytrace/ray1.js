var Ray1 = function (canvas, gl) {
    this.cameraAngle = 0;

    var vertexSourceFile = "shaders/vertex.glsl";
    var fragmentSourceFile = "shaders/fragment.glsl";

    this.indexCount = ViewIndices.length;
    this.positionVbo = createVertexBuffer(gl, ViewPositions);
    this.indexIbo = createIndexBuffer(gl, ViewIndices);
    this.shaderProgram = createShaderProgram(gl, vertexSourceFile, fragmentSourceFile);

    gl.enable(gl.DEPTH_TEST);
}

Ray1.prototype.render = function (canvas, gl, w, h) {
    gl.clearColor(1.0, 1.0, 1.0, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    // this.cubeMesh.renderRay(gl, w, h);

    // Set Shader program
    gl.useProgram(this.shaderProgram);

    // ##### ADD STUFF HERE

    // IMPORTANT: OpenGL has different matrix conventions than our JS program. We need to transpose the matrix before passing it
    // to OpenGL to get the correct matrix in the shader.
    //gl.uniformMatrix4fv(gl.getUniformLocation(this.shaderProgram, "ModelViewProjection"), 
    //    false, modelViewProjection.transpose().m);

    var d = new Date();
    var s = d.getSeconds() + (d.getMilliseconds() / 1000)
    var t = (Math.PI / 30) * ((10 * s) % 60);
    gl.uniform1f(gl.getUniformLocation(this.shaderProgram, "WindowHeight"), h)
    gl.uniform1f(gl.getUniformLocation(this.shaderProgram, "WindowWidth"), w)
    gl.uniform1f(gl.getUniformLocation(this.shaderProgram, "time"), t);
    // #### END

    // Bind index, position, and normal buffers
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.indexIbo);
    gl.bindBuffer(gl.ARRAY_BUFFER, this.positionVbo);
    var positionAttrib = gl.getAttribLocation(this.shaderProgram, "aPosition");
    if (positionAttrib >= 0) {
        gl.enableVertexAttribArray(positionAttrib);
        gl.vertexAttribPointer(positionAttrib, 3, gl.FLOAT, false, 0, 0);
    }

    // Draw...
    gl.drawElements(gl.TRIANGLES, this.indexCount, gl.UNSIGNED_SHORT, 0);
}

Ray1.prototype.dragCamera = function (dy) {
    this.cameraAngle = Math.min(Math.max(this.cameraAngle - dy * 0.5, -90), 90);
}
