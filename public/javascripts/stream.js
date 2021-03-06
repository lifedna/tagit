$(function() {
  setAnchorTarget('_blank');
  embedVideo();
  attachTogglePost();
});

$(document).ajaxComplete(function(event, request) {
  setAnchorTarget('_blank');
});

//This has to be done client side due to server sanitization not allowing the 'target' attribute
function setAnchorTarget(target) {
  $('a.' + target).attr('target', target);
}

//This has to be done client side due to server sanitization not allowing the 'iframe' attribute
function embedVideo() {
  $('#stream').on('click.video', '.video', function() {
    if ($(this).children('iframe').length > 0) return; //There is a 4px region on the bottom of the div that can still be clicked after the video has started
    
    $(this).children().toggle(false); //Hide thumbnail and play button
    
    var embed_domain;
    if ($(this).hasClass('youtube')) {
      embed_domain = 'https://youtube.com/embed/';
    }
    else if ($(this).hasClass('vimeo')) {
      embed_domain = 'https://player.vimeo.com/video/';
    }
    if (embed_domain) {
      $(this).append('<iframe width="480" height="360" src="' + embed_domain + $(this).attr('src') + '?autoplay=1" frameborder="0"></iframe>');
    }
    
    var self = this;
    $('.video').each(function() { //Revert any playing videos back to static images
      if (this != self && $(this).children('iframe').length > 0) {
        $(this).children('iframe').remove();
        $(this).children().toggle(true); //Show thumbnail and play button
      }
    });
  });
}

function attachTogglePost() {
  $('#filtered_stream').on('click.toggle_post', '.expand_button, .collapse_button', function() {
    var collapse_post = $(this).hasClass('collapse_button');
    $(this).attr('href', $(this).attr('href').replace('collapse_post=' + (!collapse_post).toString(), 'collapse_post=' + collapse_post.toString()));
    $(this).toggleClass('expand_button').toggleClass('collapse_button');
    
    var post_content = $(this).closest('.post_item').find('.content');
    post_content.children().animate({ height: 'toggle' }, ANIMATION_DURATION);
    post_content.append('<div class="loading_panel"></div>');
  });
}
