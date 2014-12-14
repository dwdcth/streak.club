
import Widget from require "lapis.html"
import underscore from require "lapis.util"

import random from math
import concat from table

import rawget from _G

config = require"lapis.config".get!

class Base extends Widget
  @widget_name: => underscore @__name or "some_widget"

  inner_content: =>

  content: (fn=@inner_content) =>
    css = @widget_classes!

    local inner
    @_opts = { class: css .. " base_widget", -> raw inner }
    @widget_id! if @js_init -- make it available for later

    inner = capture -> fn @
    element @elm_type or "div", @_opts

    if @js_init
      script type: "text/javascript", ->
        raw @js_init!

  widget_classes: =>
    @css_class or @@widget_name!

  widget_id: =>
    unless @_widget_id
      @_widget_id = "#{@@widget_name!}_#{random 0, 100000}"
      @_opts.id or= @_widget_id if @_opts
    @_widget_id

  widget_selector: =>
    "'##{@widget_id!}'"

  csrf_input: =>
    input type: "hidden", name: "csrf_token", value: @csrf_token

  raw_ssi: (fname) =>
    res = ngx.location.capture "/static/#{fname}"
    error "Failed to include SSI '#{fname}' (#{res.status})" unless res.status == 200
    raw res.body
