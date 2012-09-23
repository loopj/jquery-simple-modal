(($, window) ->

  #
  # Main modal class
  #

  class SimpleModal
    MODAL_MARGIN = 100

    constructor: (@el, settings) ->
      # Load in the settings
      @settings =
        zIndex: 9999
        showBackdrop: true
        spinnerThreshold: 400
        backdropOpacity: 0.1

      $.extend @settings, settings

      # Cancellable things
      @spinnerTimer = null
      @activeRequest = null

      # Element references
      @spinner = null
      @modal = null

      # Destroy modal when escape key is pressed
      $(document).keyup (e) => 
        @close() if e.keyCode == 27

      # Trigger a modal resize if the window size changes
      $(window).resize =>
        @resize()


    open: ->
      $body = $("body")

      # Never allow multiple backdrops or modals
      @close

      # Work out how we are going to load the data
      source = @el.attr "href"
      localData = (source.charAt(0) == "#")

      # Create and show the backdrop
      if @settings.showBackdrop
        $backdrop = $("<div id='remote-modal-backdrop'>")
          .css
            display: "none"
            backgroundColor: "#000"
            width: "100%"
            height: "100%"
            position: "fixed"
            top: 0
            left: 0
            zIndex: @settings.zIndex
            opacity: @settings.backdropOpacity
          .click =>
            @close()
          .appendTo($body)
          .fadeIn()

      # Create the loading spinner
      # TODO:JS Make this work without spin.js
      unless localData
        @spinner = null
        $loading = $("<div id='remote-modal-loading'>")
          .css
            position: "fixed"
            top: "50%"
            left: "50%"
            width: "100%"
            height: "100%"
            zIndex: @settings.zIndex + 1
          .click =>
            @close()

        @spinnerTimer = setTimeout ->
          $loading.appendTo($body)

          @spinner = new Spinner().spin();
          $loading.append(@spinner.el)
        , @settings.spinnerThreshold


      # Create the modal
      # TODO:JS Make the css customizable
      @modal = $("<div id='remote-modal'>")
        .css
          display: "none"
          zIndex: @settings.zIndex + 2
          position: "fixed"
          top: "50%"
          left: "50%"
          maxWidth: $(window).width() - MODAL_MARGIN 
          maxHeight: $(window).height() - MODAL_MARGIN
          overflow: "auto"
          backgroundColor: "white"
          borderRadius: "8px"
          boxShadow: "0 1px 3px 1px rgba(0,0,0,0.3)"
          padding: "20px"

      # Load the modal's contents
      if localData
        content = $(source).clone()
        @fill(content)
        @modal.fadeIn()
      else
        self = this
        @request = $.ajax
          url: source
          type: @el.attr("data-method") || "GET"

          success: (data) =>
            # Hide the loading dialog
            clearTimeout(@spinnerTimer)
            @spinner.stop() if @spinner

            # Show the modal (setTimeout to fix a flash in webkit transitions)
            $loading.hide()
            setTimeout =>
              @fill(data)
              @modal.fadeIn()
            , 200
              
          error: =>
            @modal.html("Could not load page")

    fill: (content) ->
      @modal
        .appendTo($("body"))
        .html(content)
        .css
          marginTop: (@modal.outerHeight() / 2) * -1
          marginLeft: (@modal.outerWidth() / 2) * -1

    close: ->
      # Remove _any_ modal DOM elements
      $("#remote-modal-backdrop").remove();
      $("#remote-modal-loading").remove();
      $("#remote-modal").remove();

      # Clear references
      @spinner = null
      @modal = null

      # Cancel requests and timers
      if @spinnerTimer
        clearTimeout(@spinnerTimer)
        @spinnerTimer = null

      if @request
        @request.abort()
        @request = null

    resize: ->
      if @modal.length
        # Adjust the max width/height
        @modal.css
          maxWidth: $(window).width() - MODAL_MARGIN
          maxHeight: $(window).height() - MODAL_MARGIN

        # Adjust the margins based on new modal size
        @modal.css
          marginTop: (@modal.outerHeight() / 2) * -1
          marginLeft: (@modal.outerWidth() / 2) * -1


  #
  # Expose as jQuery Plugin
  #

  $.extend $.fn, simpleSlider: (settingsOrMethod, params...) ->

    $(this).each ->
      settings = settingsOrMethod
      $(this).data "modal-object", new SimpleModal $(this), settings

      $(this).click ->
        modal.open()
        false


  #
  # Attach unobtrusive JS hooks
  #

  $ -> 
    $("[data-modal]").each ->
      $el = $(this)

      $el.simpleModal();

) @jQuery or @Zepto, this