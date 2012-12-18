'use strict'

define [

    'lib/zepto'
    'lib/backbone'
    'views/image'
    'models/feed'
    'utils'
    'constants'
    'text!templates/message.html'
    
], ($, Backbone, ImageView, Feed, Utils, Const, messageTemplate) ->

    Backbone.View.extend

        el: $('#pipeline')

        initialize: ->

            noneHTML = _.template messageTemplate,
                message: "There's nothing here!"
            endHTML = _.template messageTemplate,
                message: "Congrats! You've reached the end."

            @endNode = $(endHTML)
            @model = new Feed @options.subreddit
            @model.get('images').on 'add', @addImageView, @
            @model.on 'change:foundNone', => @$el.append noneHTML

            $(window).scroll @model.scroll.bind @model
            $(window).keydown @keydown.bind @

        render: ->

            @$el.html ''
            @model.loadItems()

            @

        addImageView: (model) ->

            view = new ImageView(model: model).render().el

            # Replace the temporary img node with the model's in-memory
            # image.
            image = $(view).find 'img'
            attributes = Utils.DOMAttributes image
            newImage = $(model.get('image'))
            newImage.attr attributes
            image.replaceWith newImage

            @$el.append view
            model.set
                'position': $(view).offset().top
                'height':   $(view).height()

            @$el.append @endNode if @model.get 'loadedAll'

        keyPressed: (pressedCode, keys...) ->

            for keyAttr in keys

                return true if Const.key[keyAttr] is pressedCode

            false

        keydown: (event) ->

            # Don't mess with events when shift/ctrl and arrows/paging are
            # involved (overrides browser functionality).
            if @keyPressed event.which, 'pageUp', 'pageDown', 'left', 'right'

                return if event.shiftKey or event.ctrlKey or event.metaKey

            # Set up image navigation using arrows and page up/down.
            if @keyPressed event.which, 'pageUp', 'left', 'a'

                event.preventDefault()
                @model.showPrev()

            else if @keyPressed event.which, 'pageDown', 'right', 'd'

                event.preventDefault()
                @model.showNext()

            else if @keyPressed event.which, 'v'

                event.preventDefault()
                @$('.urlBox').get(@model.get 'viewingIndex')?.select()
