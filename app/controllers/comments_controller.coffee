sanitize = require('sanitizer').sanitize

exports.getCommentsController = (app) ->

  {Post} = app.settings.models
  {postPath, commentsAnchor} = app.settings.helpers
  {markdown} = app.settings.utils

  return {

    # POST /year/month/day/:slug/comments
    create: (req, res, next) ->
      Post.findOne { slug: req.params.slug }, (err, post) ->
        # return 404 if post is not found
        unless post
          res.send 404
          return

        # parse comment
        comment = req.body.comment or {}
        markdown comment.rawContent or '', (html) ->
          comment.content = html

          # TODO: detect spam
          spam = false
          comment.spam = spam

          # save comment 
          post.comments.push(comment)
          post.save (err) ->
            if req.xhr then createXhr() else createNormal()

          # helper function for creating comment with xhr
          createXhr = ->
            if err
              res.send 400
            else
              if spam
                res.partial 'comments/spam'
              else
                res.partial 'comments/comment'
                  post: post
                  comment: post.comments[post.comments.length - 1]

          # helper function for creating comment without xhr
          createNormal = ->
            if err
              req.flash 'error', err
              res.redirect 'back'
            else
              if spam
                req.flash 'error', 'your comment is pending for review'
              else
                req.flash 'info', 'successfully posted'
              res.redirect postPath(post)

    # DEL /year/month/day/:slug/comments/:id
    destroy: (req, res, next) ->
      post = Post.findOne { slug: req.params.slug }, (err, post) ->
        if post
          post.comments.id(req.params.id).remove()
          post.save (err) ->
            if err
              res.send 400
            else
              if req.xhr
                res.send 200
              else
                res.redirect postPath(post) + commentsAnchor(post)
        else
          res.send 400
   
    # POST /comments/preview
    preview: (req, res, next) ->
      markdown req.body.rawContent or '', (html) ->
        res.send sanitize(html), 200
  }
