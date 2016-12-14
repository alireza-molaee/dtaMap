var dtaMap = (function() {
    function dtaMap(container, option) {
        option = option != null ? option : {};
        this.extent = option.extent != null ? option.extent : {
            "min_lat": "33.85581940594627",
            "max_long": "55.73730647563934",
            "min_long": "48.88183772563934",
            "max_lat": "37.21633142738797"
        };
        this.container = container;
        this.zoom = option.zoom != null ? option.zoom : 10;
        this.googleMapOptions = option.googleMapOptions != null ? option.googleMapOptions : {};

        this.initGoogleMap();
        this.initOpenLayer();

    }

    dtaMap.prototype.initGoogleMap = function () {
        $(this.container).append('<div id="dtaMap-googleMap" style="height: 100%;width: 100%;"></div>');
        this.googleMapOptions.disableDefaultUI = true;
        this.googleMapOptions.keyboardShortcuts = false;
        this.googleMapOptions.draggable = false;
        this.googleMapOptions.disableDoubleClickZoom = false;
        this.googleMapOptions.scrollwheel = false;
        this.googleMapOptions.streetViewControl = false;
        this.googleMapObject = new google.maps.Map(document.getElementById('dtaMap-googleMap'), this.googleMapOptions)
    };

    dtaMap.prototype.initOpenLayer = function () {
        var openlayerDiv;

        $(this.container).append('<div id="dtaMap-openLayerMap" style="height: 100%;width: 100%;"></div>');

        openlayerDiv = document.getElementById('dtaMap-openLayerMap');

        this.openlayer = {};

        this.openlayer.view = new ol.View();

        this.openlayer.view.on('change:center', function () {
            $('#dtaMap-openLayerMap').css("opacity", "0.3");
            var center;
            center = ol.proj.toLonLat(this.openlayer.view.getCenter());
            this.googleMapObject.setCenter(new google.maps.LatLng(center[1], center[0]))
        }, this);

        this.openlayer.view.on('change:resolution', function () {
            this.googleMapObject.setZoom(this.openlayer.view.getZoom());
        }, this);

        this.openlayer.map = new ol.Map({
            layers: [],
            interactions: ol.interaction.defaults({
                altShiftDragRotate: false,
                dragPan: false,
                rotate: false
            }).extend([new ol.interaction.DragPan({kinetic: null})]),
            overlays: [],
            renderer: 'canvas',
            target: openlayerDiv,
            view: this.openlayer.view
        });

        openlayerDiv.parentNode.removeChild(openlayerDiv);

        this.googleMapObject.controls[google.maps.ControlPosition.TOP_LEFT].push(openlayerDiv);

        this.setExtent(this.extent);
    };

    dtaMap.prototype.initSites = function () {
        this.sites = {};
        this.sites.olSource = new ol.source.Vector();
        this.sites.olLayer = new ol.layer.Vector({
            source: this.sites.olSource,
            name: 'sites'
        });
    };

    dtaMap.prototype.changeMapType = function (type) {
        $('#dtaMap-googleMap .gm-style>div:first').show();

        switch(type) {
            case 'roadmap':
                this.googleMapObject.setMapTypeId('roadmap');
                break;
            case 'satellite':
                this.googleMapObject.setMapTypeId('satellite');
                break;
            case 'none':
                setTimeout(function () {
                    $('#dtaMap-googleMap .gm-style>div:first').hide();
                }, 500)
        }
    };

    dtaMap.prototype.setExtent = function (extent) {
        var minExtent, maxExtent;

        minExtent = ol.proj.fromLonLat([Number(extent.min_long), Number(extent.min_lat)]);
        maxExtent = ol.proj.fromLonLat([Number(extent.max_long), Number(extent.max_lat)]);

        extent = [minExtent[0], minExtent[1], maxExtent[0], maxExtent[1]];

        // this.centerCordinate = ol.extent.getCenter(extent)

        this.openlayer.view.fit(extent, this.openlayer.map.getSize())

    };

    dtaMap.prototype.getExtent = function () {
        var extent;
        extent = this.openlayer.map.getView().calculateExtent(this.openlayer.map.getSize());
        return {
            min_long: extent[0],
            min_lat: extent[1],
            max_long: extent[2],
            max_lat: extent[3]
        }
    };

    dtaMap.prototype.addSites = function (sites) {

    };



    return dtaMap
})();

window.dtaMap = dtaMap;