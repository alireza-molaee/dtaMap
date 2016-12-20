var dtaMap = (function() {
    function dtaMap(container, option) {
        option = option != null ? option : {};
        option.sites = option.sites != null ? option.sites : {};

        this.sites = {
            cells: {},
            name: {},
            data: null
        };

        this.extent = option.extent != null ? option.extent : {
            "min_lat": "33.85581940594627",
            "max_long": "55.73730647563934",
            "min_long": "48.88183772563934",
            "max_lat": "37.21633142738797"
        };
        this.container = container;
        this.sites.opacity = option.sites.opacity != null ? option.sites.opacity : 0.8;
        this.sites.radius = option.sites.radius != null ? option.sites.radius : 50;
        this.sites.fill = option.sites.fill != null ? option.sites.fill : "colorful";
        this.zoom = option.zoom != null ? option.zoom : 10;
        this.googleMapOptions = option.googleMapOptions != null ? option.googleMapOptions : {};

        this.initGoogleMap();
        this.initOpenLayer();
        this.initPoints();
        this.initSites();
        this.initPopup();

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

        $(this.container).append('<div id="dtaMap-openLayerMap" style="height: 100%;width: 100%;position: relative;"></div>');

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

        this.openlayer.map.on('moveend', function () {
            $('#dtaMap-openLayerMap').css("opacity", "1");
        });

        openlayerDiv.parentNode.removeChild(openlayerDiv);

        this.googleMapObject.controls[google.maps.ControlPosition.TOP_LEFT].push(openlayerDiv);

        this.setExtent(this.extent);
    };

    dtaMap.prototype.initPoints = function () {
        this.points = {
            mapIndex: {}
        };
        this.points.layers = new ol.layer.Group();
        this.openlayer.map.addLayer(this.points.layers);
    };

    dtaMap.prototype.initSites = function () {
        var radius = this.sites.radius;
        this.sites.cells.olSource = new ol.source.Vector();
        this.sites.cells.olLayer = new ol.layer.Vector({
            source: this.sites.cells.olSource,
            name: 'sites cell',
            opacity: this.sites.opacity
        });
        this.sites.cells.olLayer.setStyle(this.getSiteStyleFunction(this.sites.fill));

        this.sites.name.olSource = new ol.source.Vector();
        this.sites.name.olLayer = new ol.layer.Vector({
            source: this.sites.name.olSource,
            name: 'sites name',
            opacity: this.sites.opacity,
            style: function (feature, resolution) {
                var offset = radius * 2;
                if (resolution > 2.4) {
                    offset = radius * 1.5 * 2
                }
                return new ol.style.Style({
                    fill: null,
                    stroke: null,
                    text: new ol.style.Text({
                        font: '11px sans-serif',
                        text: feature.get('name'),
                        offsetY: -(offset + 30 ) / resolution,
                        fill: new ol.style.Fill({color: '#000'}),
                        stroke: new ol.style.Stroke({
                            color: "#fff",
                            width: 1
                        })
                    })
                })
            }
        });

        this.openlayer.map.addLayer(this.sites.cells.olLayer);
        this.openlayer.map.addLayer(this.sites.name.olLayer);
    };

    dtaMap.prototype.initPopup = function () {
        var element, popup;
        $(this.container).append('<div id="dtaMap-popup"></div>');
        element = document.getElementById('dtaMap-popup');
        popup = new ol.Overlay({
            element: element,
            positioning: 'bottom-center',
            stopEvent: false,
            offset: [0, -50]
        });

        this.openlayer.map.addOverlay(popup);
        this.openlayer.map.on('click', function (event) {
            var feature = this.openlayer.map.forEachFeatureAtPixel(event.pixel,
                function(feature) {
                    return feature;
                });

            if (feature) {
                console.log('asd')
                var coordinates = feature.getGeometry().getCoordinates();
                popup.setPosition(coordinates);
                $(element).popover({
                    'placement': 'top',
                    'html': true,
                    'content': 'asdasd'
                });
                $(element).popover('show');
            } else {
                $(element).popover('destroy');
            }
        }, this)
    };

    dtaMap.prototype.getSiteStyleFunction = function (type) {
        var radius, getSieteStyle, siteStyleFunction;

        radius = this.sites.radius;

        getSieteStyle = function (feature, resolution) {
            var offset, azimuthDgre, azimuthRadian, offsetx, offsety, fill, stork, text;
            offset = radius;
            if (resolution > 2.4) {
                offset = radius * 1.5
            }

            azimuthDgre = (360 - (feature.get('start') + (feature.get('end') - feature.get('start')) / 2)) + 90;
            azimuthRadian = (azimuthDgre * Math.PI) / 180;
            offsetx = (Math.cos(azimuthRadian) * (offset + 10)) / resolution;
            offsety = -(Math.sin(azimuthRadian) * (offset + 10)) / resolution;

            fill = new ol.style.Fill({
                color: feature.get('color')
            });

            stork = new ol.style.Stroke({
                color: "#000",
                width: 1
            });

            text = new ol.style.Text({
                font: '11px sans-serif',
                text: feature.get('cellName'),
                offsetX: offsetx,
                offsetY: offsety,
                fill: new ol.style.Fill({color: '#000'}),
                stroke: new ol.style.Stroke({
                    color: "#fff",
                    width: 2
                })
            });

            return [fill, stork, text]
        };

        if (type === 'colorful') {
            siteStyleFunction = function (feature, resolution) {
                var styles = getSieteStyle(feature, resolution);
                return new ol.style.Style({
                    fill: styles[0],
                    stroke: styles[1],
                    text: styles[2]
                })
            }
        } else {
            siteStyleFunction = function (feature, resolution) {
                var styles = getSieteStyle(feature, resolution);
                return new ol.style.Style({
                    fill: null,
                    stroke: styles[1],
                    text: styles[2]
                })
            }
        }

        return siteStyleFunction
    };

    dtaMap.prototype.changeSitesFill = function (type) {
        this.sites.cells.olLayer.setStyle(this.getSiteStyleFunction(type))
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
        var radiusMeters = this.sites.radius;
        this.sites.data = sites;

        function calcStartEnd(cell) {
            var start, end;
            end = parseInt(cell.azimuth) + parseInt(cell.beamwidth / 2);
            start = parseInt(cell.azimuth) - parseInt(cell.beamwidth / 2);
            if (start > 360) {
                start %= 360
            }
            if (end > 360) {
                end %= 360
            }
            cell.start = start;
            cell.end = end;
        }

        function makeCellGeometry(cell, centerLat, centerLong) {
            var center, angle, points, point, centerPoint;
            points = [];
            center =  new google.maps.LatLng(centerLat, centerLong);
            angle = cell.start;
            while (angle !== cell.end) {
                point = google.maps.geometry.spherical.computeOffset(center, radiusMeters, angle);
                points.push(ol.proj.fromLonLat([point.toJSON().lng, point.toJSON().lat]));
                angle += 1;
                if (angle > 360) {
                    angle = 1;
                }
            }
            centerPoint = ol.proj.fromLonLat([center.toJSON().lng, center.toJSON().lat]);
            points.unshift(centerPoint);
            points.push(centerPoint);
            return points
        }

        function makeCellFeature(cell, centerLat, centerLong) {
            var cellGeometry, feature;
            cellGeometry = makeCellGeometry(cell, centerLat, centerLong);

            feature = new ol.Feature({
                geometry: new ol.geom.Polygon([cellGeometry]),
                cellId: cell.cell_id,
                cellName: cell.cell_name,
                color: cell.color,
                start: cell.start,
                end: cell.end,
                azimuth: cell.azimuth,
                beamwidth: cell.beamwidth
            });

            feature.setId(Number(cell.cell_id));

            return feature;
        }

        sites.forEach(function (site) {
            var labelFeature;
            site.cells.forEach(function (cell) {
                var feature;
                calcStartEnd(cell);
                feature = makeCellFeature(cell, site.lat, site.long);
                this.sites.cells.olSource.addFeature(feature);
            }, this);

            labelFeature = new ol.Feature({
                geometry: new ol.geom.Point(ol.proj.fromLonLat([Number(site.long), Number(site.lat)])),
                labelPoint: new ol.geom.Point(ol.proj.fromLonLat([Number(site.long), Number(site.lat)])),
                name: site.site_name
            });
            this.sites.name.olSource.addFeature(labelFeature);
        }, this);
    };

    dtaMap.prototype.clearSites = function () {
        this.sites.cells.olSource.clear();
        this.sites.name.olSource.clear();
    };

    dtaMap.prototype.changeSitesRadius = function (radius) {
        this.sites.radius = radius;
        this.clearSites();
        this.addSites(this.sites.data);
    };

    dtaMap.prototype.getSiteByName = function (name) {
        var filteredData;

        function checkName(site) {
            return site.site_name.includes(name);
        }

        filteredData = this.sites.data.filter(checkName);



        filteredData.forEach(function (site) {
            site.cells.forEach(function (cell) {
                cell = this.getCellById(cell.cell_id);
            }, this);
        }, this);

        if (filteredData.length === 1) {
            return filteredData[0]
        } else if (filteredData.length > 1) {
            return filteredData
        } else {
            return null
        }
    };

    dtaMap.prototype.getAllSite = function () {
      return this.getSiteByName('');
    };

    dtaMap.prototype.getCellById = function(id) {
        var cell;
        cell = this.sites.cells.olSource.getFeatureById(Number(id)).getProperties();
        delete cell.geometry;
        return cell
    };

    dtaMap.prototype.getAllcell = function () {
        var cellsFeature, cells;
        cells = [];
        cellsFeature = this.sites.cells.olSource.getFeatures();
        cellsFeature.forEach(function (feature) {
            var cell;
            cell = feature.getProperties();
            delete cell.geometry;
            cells.push(cell);
        });
        return cells;
    };

    dtaMap.prototype.changeCellColor = function (cellId, color) {
        var cell;
        cell = this.sites.cells.olSource.getFeatureById(Number(cellId));
        cell.set("color", color);
    };

    dtaMap.prototype.addPoints = function (pointsArr , file, field, legend) {
        var layer, source;
        source = new ol.source.Vector();

        pointsArr.forEach(function (point) {
            var color;
            color = this.getColorOfPoint(point[3], legend);
            source.addFeature(new ol.Feature({
                geometry: new ol.geom.Point(ol.proj.fromLonLat([Number(point[2]), Number(point[1])])),
                time: point[0],
                value: point[3],
                color: color
            }));
        }, this);

        layer = new ol.layer.Vector({
            source: source,
            name: field + ' (' + file + ')',
            style: function (feature) {
                return new ol.style.Style({
                    image: new ol.style.Circle({
                        radius: 3,
                        fill: new ol.style.Fill({
                            color: feature.get("color")
                        }),
                        stroke: null
                    })
                });
            }
        });

        if (this.points.mapIndex[field] == undefined) {
            this.points.mapIndex[field] = {}
        }

        this.points.mapIndex[field][file] = this.points.layers.getLayers().getLength();
        this.points.layers.getLayers().push(layer);
        console.log(this.points.select)
    };

    dtaMap.prototype.getColorOfPoint = function (value, legend) {
        // TODO: handle SC type and maybe make legend object
        var color;
        legend.forEach(function (item) {
            if (Number(item.range_min) <= value && Number(item.range_max) > value) {
                color = item.color;
            }
        });
        return color;
    };

    dtaMap.prototype.removeAllPoints = function () {
        this.points.layers.getLayers().clear();
    };

    dtaMap.prototype.removePoints = function (field, file) {
        this.points.layers.getLayers().removeAt(this.points.mapIndex[field][file]);
    };

    dtaMap.prototype.getLayerPoints = function (field, file) {
        return this.points.layers.getLayers().item(this.points.mapIndex[field][file]);
    };

    dtaMap.prototype.setPointsVisible = function (field, file) {
        this.getLayerPoints(field, file).setVisible(true);
    };

    dtaMap.prototype.setPointsUnvisible = function (field, file) {
        this.getLayerPoints(field, file).setVisible(false);
    };

    dtaMap.prototype.getPointsLayerLength = function () {
        return this.points.layers.getLayers().getLength()
    };

    dtaMap.prototype.setPointsZindex = function (field, file, zIndex) {
        this.getLayerPoints(field, file).setZIndex(zIndex);
    };

    return dtaMap
})();

window.dtaMap = dtaMap;