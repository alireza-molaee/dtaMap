
class OpenLayerMap

  constructor: (options) ->
    {
    @initExtend = {
      "min_lat": "33.85581940594627",
      "max_long": "55.73730647563934",
      "min_long": "48.88183772563934",
      "max_lat": "37.21633142738797"
    },
    @zoom = 10,
    @googleMapContainerId = 'googleMap',
    @olMapContainerId = 'olMap',
    @widthStorkOfLines = 2,
    @defultColor = '#000',
    @radiusMeters = 50,
    @getReportsURL = '/report/getReports',
    @cellColorPickerCssSelector = '#colorpicker ul',
    @cellDefultColor = '#1E005E',
    @RenderCompeleted = null,
    @renderLegend = false,
    @binningToGetReaport = 1
    } = options

    @isPointsRendered = false
    @isCellsRendered = false
    @isGoogleMapRendered = false
    @isEventsRendered = false

    @stat = {};

    @googleMap = new google.maps.Map(document.getElementById(@googleMapContainerId), {
      disableDefaultUI: true,
      keyboardShortcuts: false,
      draggable: false,
      disableDoubleClickZoom: true,
      scrollwheel: false,
      streetViewControl: false
    })

    @cellColorStyle = 'colorful'

    $(':radio[name=cell-color]').bind 'change', {map: @}, (evt) ->
      mapObj = evt.data.map
      mapObj.cellColorStyle = $(@).val()
      mapObj.setCellStyle()

    @filesAvailable = {}

    @cellColor = {}
    @view = new ol.View

    @view.on 'change:center', () ->
      $(@.olMapDiv).css("opacity", "0.3")
      center = ol.proj.toLonLat @view.getCenter()
      @googleMap.setCenter(new google.maps.LatLng(center[1], center[0]))
    , @

    @view.on 'change:resolution', () ->
      zoom = @view.getZoom()
      @googleMap.setZoom(zoom)
    , @

    @vectorSource = new ol.source.Vector

    @vector = new ol.layer.Vector
      source: @vectorSource
      name: 'points'

    @setLayerStyle()

    @eventVectorSource = new ol.source.Vector

    @eventVector = new ol.layer.Vector
      source: @eventVectorSource
      name: 'events'

    @setEventStyle()

    @cellSource = new ol.source.Vector

    @cellVector = new ol.layer.Vector
      source: @cellSource,
      opacity: 0.6

    @setCellStyle()

    @siteNameSource = new ol.source.Vector

    @siteNameLayer = new ol.layer.Vector
      source: @siteNameSource,
      opacity: 0.6

    @setSiteNameStyle()



    @extentSource = new ol.source.Vector

    @extentVector = new ol.layer.Vector
      source: @extentSource,
      style: new ol.style.Style
        stroke: new ol.style.Stroke
          width: 3,
          color: [255, 0, 0, 1]


    container = document.getElementById('popup');
    content = document.getElementById('popup-content');
    closer = document.getElementById('popup-closer');

    popup = new ol.Overlay {
      element: container,
      autoPan: true,
      autoPanAnimation: {
        duration: 250
      }
    }

    closer.onclick = () ->
      popup.setPosition(undefined)
      closer.blur()
      return false


    @olMapDiv = document.getElementById @olMapContainerId

    @map = new ol.Map
      layers: [@vector, @eventVector, @cellVector, @siteNameLayer],
      interactions: ol.interaction.defaults({
        altShiftDragRotate: false,
        dragPan: false,
        rotate: false
      }).extend([new ol.interaction.DragPan({kinetic: null})]),
      overlays: [popup],
      renderer: 'canvas',
      target: @olMapDiv,
      view: @view

    @select = new ol.interaction.Select()
    @map.addInteraction(@select);

    @selectedFeatures = @select.getFeatures();

    @dragBox = new ol.interaction.DragBox({
      condition: ol.events.condition.platformModifierKeyOnly
    });

    @map.addInteraction(@dragBox);

    @dragBox.on 'boxend', () ->
      extent = @.dragBox.getGeometry().getExtent()
      fetures = @.vectorSource.getFeaturesInExtent extent
      fetures.forEach (feature) ->
        @.selectedFeatures.push(feature)
      , @
    , @

    @dragBox.on 'boxstart', () ->
      @selectedFeatures.clear()
    , @

    $("html").on "keydown", null, @, (event) ->
      params = {}
      if event.keyCode == 46
        event.data.selectedFeatures.forEach (feature) ->
          if params[feature.get("fileId")] == undefined
            params[feature.get("fileId")] = [{
              field: feature.get("field")
              device: feature.get("fieldIndex")
              coordinate: ol.proj.toLonLat feature.getGeometry().getCoordinates()
              val: feature.get("val")
            }]
          else
            params[feature.get("fileId")].push({
              field: feature.get("field")
              device: feature.get("fieldIndex")
              coordinate: ol.proj.toLonLat feature.getGeometry().getCoordinates()
              val: feature.get("val")
            })

        $.ajax {
          url: "/report/CorrectPoints",
          data: $.param({data: JSON.stringify(params)}),
          cache: false,
          method: 'POST',
          dataType: 'json',
          complete: (xhr) ->
            if xhr.status == 200
              event.data.selectedFeatures.forEach (feature) ->
                event.data.vectorSource.removeFeature(feature)
              event.data.selectedFeatures.clear()
        }


    @map.on 'moveend', (event) ->
      $(@.olMapDiv).css("opacity", "1")
    , @

    @map.on 'click', (evt) ->
      @selectedFeatures.clear()
      filesAvailable = @filesAvailable
      @map.forEachFeatureAtPixel evt.pixel, (feature, layer) ->
        featureFile = null
        if layer.get('name') == 'points'
          for file in filesAvailable
            do (file) ->
              if file.id == Number(feature.get('fileId'))
                featureFile = file
                console.log(featureFile)
              return

          content.innerHTML = '<div><h2>' + feature.get('field') + '</h2><p> ٰValue: ' + feature.get('val') + '</p><p> File address: ' + featureFile.address + '</p><p> File comment: ' + featureFile.comment + '</p><p> Date: ' + featureFile.date + '</p></div>'
          popup.setPosition(evt.coordinate)
    , @

    @setExtent(@initExtend)

    @olMapDiv.parentNode.removeChild(@olMapDiv);

    @googleMap.controls[google.maps.ControlPosition.TOP_LEFT].push(@olMapDiv);

    self = @

    google.maps.event.addListenerOnce @googleMap, 'idle', () ->
      self.isGoogleMapRendered = true
      self.checkRenderCompeleted()

  changeMapType: (type) ->
    googleMapcontainerId = @googleMapContainerId
    $('#' + googleMapcontainerId + ' .gm-style>div:first').show()
    switch type
      when 'roadmap' then @googleMap.setMapTypeId('roadmap');
      when 'satellite' then @googleMap.setMapTypeId('satellite');
      when 'none'
        setTimeout(
          () ->
            $('#' + googleMapcontainerId + ' .gm-style>div:first').hide()
        , 1000
        )

  setExtent: (extent) ->
    minExtend = ol.proj.fromLonLat([Number(extent.min_long), Number(extent.min_lat)])
    maxExtend = ol.proj.fromLonLat([Number(extent.max_long), Number(extent.max_lat)])

    extent = [minExtend[0], minExtend[1], maxExtend[0], maxExtend[1]]
    @centerPosition = ol.extent.getCenter(extent)

    extentFeature = new ol.Feature
      geometry: new ol.geom.LineString([
        [minExtend[0], maxExtend[1]],
        [minExtend[0], minExtend[1]],
        [maxExtend[0], minExtend[1]],
        [maxExtend[0], maxExtend[1]],
        [minExtend[0], maxExtend[1]]
      ])

    @extentSource.clear()
    @extentSource.addFeature(extentFeature)
    @view.fit(extent, @map.getSize())

  checkRenderCompeleted: () ->
    if @isPointsRendered && @isCellsRendered && @isGoogleMapRendered && @RenderCompeleted
      @RenderCompeleted(@)


  getPicture: (callBack) ->
    transform = $(".gm-style>div:first>div").css("transform")
    comp = transform.split(",")
    mapleft = parseFloat(comp[4])
    maptop = parseFloat(comp[5])
    $(".gm-style>div:first>div").css({
      "transform": "none",
      "left": mapleft,
      "top": maptop,
    })

    MapContainerId = '#' + @googleMapContainerId

    html2canvas(
      $(MapContainerId),
      {
        useCORS: true,
        onrendered: (canvas) ->
          dataUrl = canvas.toDataURL('image/png');
          callBack(dataUrl)
          $(".gm-style>div:first>div").css({
            left: 0,
            top: 0,

          })
      }
    )

  getExtend: () ->
    extend = @map.getView().calculateExtent(@map.getSize())
    bound =
      'topLeft': ol.proj.toLonLat([extend[0], extend[1]]),
      'bottomRight': ol.proj.toLonLat([extend[2], extend[3]])
    return bound

  setSiteNameStyle: () ->
    radius = @radiusMeters
    func = (feature, resolution) ->
      text = feature.get('name')
      if resolution > 2.4
        offset = radius * 1.5
      else
        offset = radius


      return new ol.style.Style({
        fill: null,
        stroke: null,
        text: new ol.style.Text({
          font: '11px sans-serif'
          text: text,
          offsetY: -(offset * 2 + 20 ) / resolution,
          fill: new ol.style.Fill({color: '#000'}),
          stroke: new ol.style.Stroke({
            color: "#fff",
            width: 2
          }),
        })
      })

    @siteNameLayer.setStyle func

  setEventStyle: () ->
    func = (feature, resolution) ->
      text = feature.get('name')

      return new ol.style.Style({
        fill: null,
        stroke: null,
        image: new ol.style.Icon(({
          scale: 0.3
          src: '/static/img/Hand.png'
        }))
      })

    @eventVector.setStyle func


  setCellStyle: () ->
    radius = @radiusMeters
    cellStyleFunctionColorful = (feature, resolution) ->
      if resolution > 2.4
        offset = radius * 1.5
      else
        offset = radius

      text = feature.get('cellName').slice(0, -2)
      azimuth1 = (360 - (feature.get('start') + (feature.get('end') - feature.get('start')) / 2)) + 90
      azimuth2 = (azimuth1 * Math.PI) / 180
      offsetx = (Math.cos(azimuth2) * (offset + 10)) / resolution
      offsety = -(Math.sin(azimuth2) * (offset + 10)) / resolution

      return new ol.style.Style({
        fill: new ol.style.Fill({
          color: feature.get('color')
        }),
        stroke: new ol.style.Stroke({
          color: "#000",
          width: 1
        }),
        text: new ol.style.Text({
          font: '11px sans-serif'
          text: text,
          offsetX: offsetx,
          offsetY: offsety,
          fill: new ol.style.Fill({color: '#000'}),
          stroke: new ol.style.Stroke({
            color: "#fff",
            width: 3
          }),
        })
      })

    cellStyleFunctionNonColor = (feature, resolution) ->
      if resolution < 2.4
        text = feature.get('cellName')
      else
        text = ''

      return new ol.style.Style({
        fill: null,
        stroke: new ol.style.Stroke({
          color: "#000",
          width: 1
        }),
        text: new ol.style.Text({
          font: '11px sans-serif'
          text: text,
          fill: new ol.style.Fill({color: '#fff'}),
          stroke: new ol.style.Stroke({
            color: "#434343",
            width: 2
          }),
        })
      })

    if @cellColorStyle == 'colorful'
      @cellVector.setStyle(cellStyleFunctionColorful)
    else
      @cellVector.setStyle(cellStyleFunctionNonColor)

  setLayerStyle: () ->
    defultColor = @defultColor
    legends = @legends
    cellsColor = @cellColor

    styleFunction = (feature) ->
      style = null
      value = Number(feature.get('val'))
      fieldIndex = Number(feature.get('fieldIndex'))

      asdasd = JSON.parse(legends[fieldIndex][2])

      for legend in asdasd
        do (legend) ->
          if Number(legend['range_min']) <= value and Number(legend['range_max']) > value
            style = new ol.style.Style({
              image: new ol.style.Circle({
                radius: 3,
                fill: new ol.style.Fill({
                  color: legend['color']
                }),
                stroke: null
              })
            })
      if !style
        style = new ol.style.Style({
          image: new ol.style.Circle({
            radius: 3,
            fill: new ol.style.Fill({
              color: defultColor
            }),
            stroke: null
          })
        })
      if cellsColor[value.toString() + '_0'] or cellsColor[value.toString() + '_0']
        color = cellsColor[value.toString() + '_0']['color']
        style = new ol.style.Style({
          image: new ol.style.Circle({
            radius: 3,
            fill: new ol.style.Fill({
              color: color
            }),
            stroke: null
          })
        })
      return style


    @vector.setStyle(styleFunction)


  getState: (template) ->
    stat = for legend in @newLegend
      do (legend) ->
        if legend.count != undefined
          if template == 1 and legend.count != 0
            return {
              color: legend.color,
              range: legend.range_min + " (" + legend.count + ")",
              persentage: Math.round((legend.count / legend.totalPointCount) * 100) + "%"
            }
          else if template == 0
            return {
              color: legend.color,
              range: legend.range_min + "_" + legend.range_max + "&nbsp; (" + legend.count + ")",
              persentage: Math.round((legend.count / legend.totalPointCount) * 100) + "%"
            }
    return stat

  addPoints: (data) ->
    geoFeatures = for point in data['result']
      do (point) ->
        {
          'type': 'Feature',
          'properties': {
            'val': Number(point[3]),
            'fileId': fileId,
            'field': field,
            'fieldIndex': fieldIndex
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [Number(point[2]), Number(point[1])]
          }
        }
    geojsonObject = {
      'type': 'FeatureCollection',
      'crs': {
        'type': 'name',
        'properties': {
          'name': 'EPSG:4326'
        }
      },
      'features': geoFeatures
    }
    @renderPoint(geojsonObject)

  reqForPointJSON: (fileId, field, fieldIndex, device) ->
    params =
      file_id: fileId,
      field: field,
      device: device,
      binning: @binningToGetReaport

    rawLegend = []

    if @legends[fieldIndex] != undefined
      rawLegend = JSON.parse(@legends[fieldIndex][2])


    $.ajax {
      context: @,
      url: @getReportsURL,
      data: $.param(params),
      cache: false,
      method: 'POST',
      dataType: 'json',
      error: (jqXHR, textStatus, errorThrown) ->
        console.log jqXHR
      success: (data, textStatus, jqXHR) ->
#        console.log data['result'].length
        totalPointCount = data['result'].length
        newLegend = [];
        geoFeatures = for point in data['result']
          do (point) ->
            for legend, index in rawLegend
              do (legend, index) ->
                if legend.count == undefined
                  legend.count = 0
                legend.totalPointCount = totalPointCount
#                console.log(point[3])
                if Number(legend['range_min']) <= Number(point[3]) and Number(legend['range_max']) > Number(point[3])
                  legend.count++

                rawLegend[index] = legend

            if point[3] == ""
              point[3] = 0

            newLegend = rawLegend


            return {
              'type': 'Feature',
              'properties': {
                'val': Number(point[3]),
                'fileId': fileId,
                'field': field,
                'fieldIndex': fieldIndex
              },
              'geometry': {
                'type': 'Point',
                'coordinates': [Number(point[2]), Number(point[1])]
              }
            }

        geoEventFeatures = for point in data['events']
          do (point) ->
            return {
              'type': 'Feature',
              'properties': {
                'val': Number(point[3]),
                'fileId': fileId,
                'field': field,
                'fieldIndex': fieldIndex
              },
              'geometry': {
                'type': 'Point',
                'coordinates': [Number(point[2]), Number(point[1])]
              }
            }

        @newLegend = newLegend

        geojsonObject = {
          'type': 'FeatureCollection',
          'crs': {
            'type': 'name',
            'properties': {
              'name': 'EPSG:4326'
            }
          },
          'features': geoFeatures
        }

        eventGeojsonObject = {
          'type': 'FeatureCollection',
          'crs': {
            'type': 'name',
            'properties': {
              'name': 'EPSG:4326'
            }
          },
          'features': geoEventFeatures
        }

        @.renderIcon(eventGeojsonObject)
        @.renderPoint(geojsonObject)
    }

  renderIcon: (geoEventFeatures) ->
    features = (new ol.format.GeoJSON()).readFeatures(geoEventFeatures, {
      featureProjection: 'EPSG:3857'
    })

    @eventVectorSource.addFeatures(features)

#    @isEventsRendered = true
#    @checkRenderCompeleted()

  ###
  Read features from geoJSON then add features
  @param [JSON] geojsonObject geoJSON
  ###
  renderPoint: (geojsonObject) ->
    features = (new ol.format.GeoJSON()).readFeatures(geojsonObject, {
      featureProjection: 'EPSG:3857'
    })
    @vectorSource.addFeatures(features)
    if @renderLegend
      @makeLegend()

    @isPointsRendered = true
    @checkRenderCompeleted()


  ###
  Remove point feture by fileId and field
  @param [String] fileId fileId
  @param [String] field field
  ###
  removePoint: (fileId, field) ->
    checkToDestroy = (feature) ->
      featureProperties = feature.getProperties()
      if (featureProperties.fileId == fileId and featureProperties.field == field)
        @vectorSource.removeFeature feature
    @vectorSource.forEachFeature checkToDestroy, @

    if @renderLegend
      @makeLegend()

  ###
  Remove all point features from sourse.
  ###
  removeAllPoint: () ->
    @vectorSource.clear()
    if @renderLegend
      @makeLegend()


  makeLegend: () ->
    $("#legends").html('')
    legends = @legends
    finalLegends = {}
    @vectorSource.forEachFeature (feature) ->
      if finalLegends[feature.get('field')] == undefined
        finalLegends[feature.get('field')] = {}

      if finalLegends[feature.get('field')]["totalCount"] == undefined
        finalLegends[feature.get('field')]["totalCount"] = 0

      if finalLegends[feature.get('field')]["fieldIndex"] == undefined
        finalLegends[feature.get('field')]["fieldIndex"] = feature.get('fieldIndex')

      finalLegends[feature.get('field')]["totalCount"]++

      JSON.parse(legends[feature.get('fieldIndex')][2]).forEach (item) ->
        if Number(item['range_min']) <= feature.get("val") and Number(item['range_max']) > feature.get("val")
          if finalLegends[feature.get('field')][item.range_max + " _ " + item.range_min] == undefined
            finalLegends[feature.get('field')][item.range_max + " _ " + item.range_min] = 0
          finalLegends[feature.get('field')][item.range_max + " _ " + item.range_min]++

    html = "<div>"

    for field, details of finalLegends
      html += '<div><h4>' + field + '</h4>'
      JSON.parse(legends[details["fieldIndex"]][2]).forEach (legend, index) ->
        if JSON.parse(legends[details["fieldIndex"]][2]).length - 1 == index
          max = "above"
        else
          max = legend.range_max

        if index == 0
          min = "below"
        else
          min = legend.range_min

        if details[legend.range_max + " _ " + legend.range_min] == undefined
          html += '<p class="stat-item"><span style="background: ' + legend.color + ';"></span>' + max + ' _ ' + min + '<span></span>&nbsp;<span>(0)&nbsp;' + '0%' + '</span></p>'
        else
          html += '<p class="stat-item"><span style="background: ' + legend.color + ';"></span>' + max + ' _ ' + min + '<span></span>&nbsp;<span>(' + details[legend.range_max + " _ " + legend.range_min] + ')&nbsp;' + Math.round((details[legend.range_max + " _ " + legend.range_min]/details.totalCount) * 100) + '%' + '</span></p>'
      html += '</div>'

    html += '</div>'

    $("#legends").append(html)


  ###
  Change legends and reset style of layer by new legends
  @param [Array<Object>] array legends
  ###
  setLegend: (array) ->
    @legends = array
    @setLayerStyle()

  ###
  For a slice details make polygon feature and add it to source then add color picker for that feature.
  @param [Array<Number, String>] slice Slice details
  ###
  addSliceToSource: (slice) ->
    vertices = @getArcPath(slice)
    if !@cellColor[slice[2]]
      @cellColor[slice[2]] = {
        color: slice[4],
        defult: true
      }

    feature = new ol.Feature
      geometry: new ol.geom.Polygon([vertices]),
      cellId: slice[2],
      cellName: slice[2],
      color: @cellColor[slice[2]]['color'],
      start: slice[0],
      end: slice[1],

    @cellSource.addFeature(feature)
    $(@cellColorPickerCssSelector).append('<li data-id="' + slice[2] + '"><label>' + slice[3] + '</label><input type="color" value="' + @cellColor[slice[2]]['color'] + '"/></li>')


  ###*
  for slice details calculate points
  @param [Array<Number, String>] slice Slice details
  @return [Array<Array>]	points of polygon
  ###
  getArcPath: (slice) ->
    center = new google.maps.LatLng(@cellsObj.lat, @cellsObj.long)
    #		if @view.getResolution() <= 2.5
    #			radiusMeters = @view.getResolution()*@radiusMeters
    #		else
    radiusMeters = @radiusMeters
    startAngle = slice[0]
    endAngle = slice[1]
    angle = startAngle
    points = []
    points = until angle == endAngle
      point = google.maps.geometry.spherical.computeOffset(center, radiusMeters, angle)
      angle += 1
      if angle > 360
        angle = 1
      ol.proj.fromLonLat([point.toJSON().lng, point.toJSON().lat])
    center = ol.proj.fromLonLat([center.toJSON().lng, center.toJSON().lat])
    points.unshift(center);
    points.push(center)
    return points

  ###
  Remove all cells
  ###
  claerCells: () ->
    @cellSource.clear()


  ###
  for each site in siteObject calls add
  @param [Array] sites array
  ###
  addSites: (arr) ->
    self = @
    arr.forEach (site) ->
      self.addCells(site)

    @isCellsRendered = true
    @checkRenderCompeleted()
    return

  ###
  for each cell in site call OpenLayerMap#autoSlices
  @param [Object] object site of cells object
  ###
  addCells: (object) ->
    @cellsObj = object
    @siteNameSource.addFeature(
      new ol.Feature
        geometry: new ol.geom.Point(ol.proj.fromLonLat([Number(object.long), Number(object.lat)])),
        labelPoint: new ol.geom.Point(ol.proj.fromLonLat([Number(object.long), Number(object.lat)])),
        name: object.site_name
    )

    @autoSlices(cell) for cell in @cellsObj.cells


  ###
  calculate silice details and then add slice to source by call OpenLayerMap#addSliceToSource
  @param [Object] cell one cell in site
  ###
  autoSlices: (cell) ->
    @slices = []
    azimuth = parseInt(cell.azimuth)
    end = azimuth + parseInt(cell.beamwidth / 2)
    start = azimuth - parseInt(cell.beamwidth / 2)
    if start > 360
      start %= 360
    if end > 360
      end %= 360
    @slices.push [start, end, cell.cell_id + '_0', cell.cell_name, cell.color]
    @addSliceToSource(slice) for slice in @slices
    return

  ###
  change color of cell and point with the cellId
  @param [String] cellID cellID
  @param [String] color color
  ###
  changeCellColor: (cellID, color) ->
    changeCellFeatureColor = (feature) ->
      if feature.get('cellId') == cellID
        feature.set('color', color)
    @cellColor[cellID]['color'] = color
    @cellColor[cellID]['defult'] = false
    @setCellStyle()

    pointStyle = new ol.style.Style({
      image: new ol.style.Circle({
        radius: 3,
        fill: new ol.style.Fill({
          color: color
        }),
        stroke: null
      })
    })

    changePointFeatureColor = (feature) ->
      cellBaseId = Number(cellID.toString().slice(0, -2))
      value = feature.get('val')
      if cellBaseId == value
        feature.setStyle pointStyle

    @cellSource.forEachFeature changeCellFeatureColor
    @vectorSource.forEachFeature changePointFeatureColor

window.OpenLayerMap = OpenLayerMap