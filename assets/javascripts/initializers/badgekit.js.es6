export default {
  name: 'badgekit',

  initialize: function() {
    Discourse.PostView.reopen({
      addBadges: function($post) {
        var userId = $post.find('article').data('user-id');

        $.ajax('/badgekit', {
          data: { userId: userId },
          success: function (data) {
            if (data.badges.length) {
              $post.find('.topic-avatar').append('<img class="badgekit-badge" src="' + data.badges[0].imageUrl + '">');
            }
          }
        });
      }.on('postViewInserted')
    });
  }
}