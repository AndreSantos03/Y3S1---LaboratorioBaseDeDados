<?php
 
namespace App\Http\Controllers;

use App\Models\Comment;
use App\Models\Post;
use Illuminate\Http\Request;

use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;

use Illuminate\View\View;

class CommentController extends Controller
{
    
    /**
     * Shows all comments for a post.
     */
    public function showForPost($postId)
    {
        // Find the post.
        $post = Post::findOrFail($postId);

        // Get all comments for the post ordered by date.
        $comments = $post->comments()->orderByDesc('commentdate')->get();

        // Use the pages.comments template to display all comments.
        return view('pages.post', [
            'post' => $post,
            'comments' => $comments
        ]);
    }

    /**
     * Shows all posts.
     */
    public function list()
    {
        // Check if the user is logged in.
        if (!Auth::check()) {
            // Not logged in, redirect to login.
            return redirect('/login');

        } else {
            // The user is logged in.

            // Get posts for user ordered by date.
            $posts = Auth::user()->posts()->orderByDesc('postdate')->get();

            // Check if the current user can list the posts.
            $this->authorize('list', comment::class);

            // The current user is authorized to list posts.

            // Use the pages.posts template to display all posts.
            return view('pages.posts', [
                'posts' => $posts
            ]);
        }
    }

    /**
     * Creates a new comment.
     */
    public function create(Request $request, int $id)
    {
        // Find the post.
        $post = Post::findOrFail($id);

        // Create a new comment instance.
        $comment = new Comment();

        // Check if the current user is authorized to create this comment.
        $this->authorize('create', $comment);

        // Validate the request data.
        $request->validate([
            'title' => ['required'],
            'caption' => ['required'],
            'image' =>  'image|max:2048|mimes:jpg,jpeg,svg,gif,png',
        ]);

        // Set comment details.
        $comment = Auth::user()->comments()->create([
            'title' => $request->input('title'),
            'caption' => $request->input('caption'),
            'commentdate' => now(), // Set the current date and time.
            'user_id' => Auth::user()->id,
            'post_id' => $request->route('id')
        ]);

        // Save the comment
        $comment->save();

        // Check if image is not null
        if (!empty($request->image)) {
            
            $response = ImageCommentController::create($request, $comment->id);
            if ($response != '200') {
                // Delete the comment
                $comment->delete();

                // Return error Message                
                return redirect()->route('posts.show', ['id' => $id])->with('error', 'Could not create comment.');
            }
        }

        return redirect()->route('posts.show', ['id' => $id])->with('success', 'Comment created successfully');
    }

    /**
    * Show the form for editing a specific comment.
    */
    public function edit($id)
    {
        $comment = Comment::findOrFail($id);

        // Check if the current user is authorized to edit this comment
        $this->authorize('update', $comment);

        return view('pages.edit_comment', ['comment' => $comment]);
    }

    /**
    * Update the specified comment in storage.
    */
    public function updateComment(Request $request, $id)
    {
        $comment = Comment::findOrFail($id);

        // Check if the current user is authorized to update this comment
        $this->authorize('update', $comment);

        $request->validate([
            'title' => ['required'],
            'caption' => ['required'],
        ]);

        // Update comment details
        $comment->title = $request->input('title');
        $comment->caption = $request->input('caption');

        // Save the updated comment
        $comment->save();

        return redirect()->route('posts.show', ['id' => $comment->post_id])->with('success', 'Comment updated successfully');
    }

    /**
     * Delete a comment.
     */
    public function delete(Request $request, $id)
    {
        // Find the comment.
        $comment = Comment::findOrFail($id);

        // Check if the current user is authorized to delete this comment.
        $this->authorize('delete', $comment);

        try {
            $comment->delete();
            return redirect()->route('posts.show', ['id' => $comment->post_id])->with('success', 'Comment deleted successfully');
        } catch (\Exception $e) {
            \Log::error('Failed to delete comment with ID: ' . $comment->id . '. Error: ' . $e->getMessage());
            return redirect()->route('posts.show', ['id' => $comment->post_id])->with('error', 'Failed to delete the comment');
        }
    }
}
?>