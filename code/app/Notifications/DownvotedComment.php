<?php
namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use App\Models\User;
use App\Models\Post;

class DownvotedComment extends Notification
{

    
    protected $downvoter;
    protected $comment;

    public function __construct(User $downvoter, Comment $comment)
    {
        $this->downvoter = $downvoter;
        $this->comment = $comment;
    }

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toDatabase(object $notifiable): array
    {
        return [
            'sender_id' => $this->downvoter->id,
            'name' => $this->downvoter->name,
            'title' => $this->comment->title,
            'description' => "Downvoted Comment",
        ];
    }
}
?>