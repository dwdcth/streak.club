
lapis = require "lapis.init"

config = require"lapis.config".get!

import Uploads from require "models"
import image_signature, unb64_from_url from require "helpers.images"
import unescape from require "socket.url"

image_log = (msg) ->
  ngx.var.image_log = msg

time = ->
  ngx.update_time!
  ngx.now!

fmt_time = (t) ->
  "%0.2f"\format t

lapis.serve class extends lapis.Application
  layout: false

  "/*": =>
    splat = @params.splat
    splat = splat\match("^img/(.*)") or splat

    key, size, signature, ext = splat\match "^([^/]+)/([^/]+)/([^/]+)%.(%w+)$"

    unless key
      image_log "bad url"
      return status: 404, "not found"

    unless signature == image_signature "#{key}/#{size}"
      image_log "bad signature"
      return status: 404, "not found (bad signature)"

    key = unb64_from_url key

    start = time!
    local image_blob
    file, load_err = io.open "#{config.user_content_path}/#{key}", "r"

    if file
      image_blob = file\read "*a"
      file\close!

    load_time = fmt_time time! - start

    unless image_blob
      image_log "not found (dl: #{load_time})"
      return status: 404, "not found (#{load_err})"

    cache_name = ngx.md5(@params.splat) .. "." .. ext

    if size != "original" and ext != "gif"
      start = time!
      import thumb, load_image_from_blob from require "magick"
      image_blob = thumb load_image_from_blob(image_blob), (unescape size)
      resize_time = fmt_time time! - start
      image_log "resize #{key} -> #{cache_name} (load: #{load_time}) (res: #{resize_time})"
    else
      image_log "skip #{key} -> #{cache_name} (load: #{load_time})"

    file = assert io.open "cache/#{cache_name}", "w"
    pcall -> file\write image_blob
    file\close!

    ngx.header["x-image-cache"] = "miss"
    ngx.header["x-image-cache-name"] = cache_name
    content_type: Uploads.content_types[ext], image_blob

