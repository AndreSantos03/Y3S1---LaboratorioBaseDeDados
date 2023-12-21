<?php
namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use App\Models\User;
use App\Models\Post;

class CommentPost extends Notification
{

    
    protected $commenter;
    protected $post;

    public function __construct(User $commenter, Post $post)
    {
        $this->commenter = $commenter;
        $this->post = $post;
    }

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toDatabase(object $notifiable): array
    {
        return [
            'sender_id' => $this->commenter->id,
            'name' => $this->commenter->name,
            'title' => $this->post->title,
            'description' => "Commented Post",
        ];
    }
}
?>