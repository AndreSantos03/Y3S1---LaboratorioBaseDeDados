<?php

namespace App\Policies;

use App\Models\User;
use Illuminate\Auth\Access\Response;

use Illuminate\Support\Facades\Auth;

class UserPolicy
{

    /**
     * Determine whether the user can view the user.
     */
    public function show(User $user): bool
    {
        return true;
    }

    /**
     * Determine whether the user can update the user.
     */
    public function update(User $user): bool
    {
        return Auth::user()->id === $user->id;
    }

    /**
     * Determine whether the user can delete the user.
     */
    public function delete(User $user): bool
    {
        return Auth::user()->id === $user->id || $user->isAdmin;
    }
}
