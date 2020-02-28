Slider = function(targetId, minValue, maxValue, initialValue, hasLabel, callback) {
    var target = document.getElementById(targetId);
    if (!target)
        return;
        
    this.sliderBackground = document.createElement("div");
    this.sliderBackground.className = "slider";
    
    this.minValue = minValue;
    this.maxValue = maxValue;
    this.callback = callback;
    
    this.sliderBar = document.createElement("div");
    this.sliderBar.className = "slider-bar";
    this.sliderBackground.appendChild(this.sliderBar);
    
    this.sliderHandle = document.createElement("a");
    this.sliderHandle.className = "slider-handle";
    this.sliderBackground.appendChild(this.sliderHandle);
    
    var mouseMoveListener = this.mouseMove.bind(this);
    function mouseUpListener(event) {
        document.removeEventListener("mousemove", mouseMoveListener);
        document.removeEventListener("mouseup", mouseUpListener);
    }
    
    this.sliderHandle.addEventListener("mousedown", function(event) {
        event.preventDefault();
        document.addEventListener("mousemove", mouseMoveListener);
        document.addEventListener("mouseup", mouseUpListener);
    });
    
    var parent = target.parentNode;
    parent.replaceChild(this.sliderBackground, target);
    
    if (hasLabel) {
        this.label = document.createElement("p");
        this.label.className = "slider-label";
        parent.insertBefore(this.label, this.sliderBackground.nextSibling);
    }

    this.setPosition((initialValue - minValue)/(maxValue - minValue));
}

Slider.prototype.mouseMove = function(event) {
    var rect = this.sliderBackground.getBoundingClientRect();
    this.setPosition((event.clientX - rect.left)/(rect.right - rect.left));
}

Slider.prototype.setLabel = function(text) {
    if (this.label)
        this.label.textContent = text;
}

Slider.prototype.setValue = function(value) {
    value = Math.min(this.maxValue, Math.max(this.minValue, value));
    if (value != this.value) {
        this.value = value;
        var percentage = Math.max(Math.min(Math.floor(100.0*(value - this.minValue)/(this.maxValue - this.minValue)), 100.0), 0.0);
        this.sliderHandle.style.left = this.sliderBar.style.width = percentage.toString() + "%";
        
        if (this.callback)
            this.callback(value);
    }
}

Slider.prototype.setPosition = function(position) {
    this.setValue(Math.floor(this.minValue + position*(this.maxValue - this.minValue)));
}

Slider.prototype.show = function(show) {
    var display = show ? "block" : "none";
    this.sliderBackground.style.display = display;
    if (this.label)
        this.label.style.display = display;
}
