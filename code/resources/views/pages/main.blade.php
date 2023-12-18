@extends('layouts.app')

@section('title', 'News Feed')

@section('header', 'News Feed')

@section('content')
    

    {{-- for the date picker --}}
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">

    <div class="search&sort">
        <form action="{{ route('posts.search') }}" method="GET">
            <input id="search_term" name="search_term" type="text" value="{{ old('search_term') }}" placeholder="Search for News">
            @if ($errors->has('search_term'))
                <span class="error">
                    {{ $errors->first('search_term') }}
                </span>
            @endif    
            <button type="submit">Search</button>
        </form>
        <br>
    </div>
    <div class="create_post">
        <button id="create_post">+</button>
    </div>

    {{-- Sort Options Dropdown --}}
    <div class="sort-options">
        <label for="sort_by">Sort By:</label>
        <select id="sort_by" name="sort">
            <option value="voteDown">Votes - Most to Least</option>
            <option value="voteUp">Votes - Least to Most</option>
            <option value="dateDown">Date - Newest to Oldest</option>
            <option value="dateUp">Date - Oldest to Newest</option>
        </select>
        
        <!-- Time Sort Dropdown -->
        <label for="time_sort">Time Sort:</label>
        <select id="time_sort" name="time_sort">
            <option value="all_time">All Time</option>
            <option value="last_24_hours">Last 24 Hours</option>
            <option value="last_week">Last Week</option>
            <option value="last_month">Last Month</option>
            <option value="last_year">Last Year</option>
        </select>
    </div>


      {{-- Filters Dropdown --}}
      <div class="filters-dropdown">
        <button id="filter_button">Show Filters</button>
        <div id="filters" style="display: none;">
            <form id="filterForm">
                @csrf
                <!-- Minimum date filter -->
                <label for="minimum_date">Minimum Date:</label>
                <input type="text" id="minimum_date" name="minimum_date">

                <!-- Maximum date filter -->
                <label for="maximum_date">Maximum Date:</label>
                <input type="text" id="maximum_date" name="maximum_date">

                <script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
                <script src="{{ asset('js/datePickerConfig.js') }}"></script>
                <script>
                    initializeDatePickers();
                </script>

                <!-- Upvote filter -->
                <label for="minimum_upvote">Minimum Upvote:</label>
                <input type="number" id="minimum_upvote" name="minimum_upvote" min="0">
                <label for="maximum_upvote">Maximum Upvote:</label>
                <input type="number" id="maximum_upvote" name="maximum_upvote" min="0">
        
                <!-- Downvote filter -->
                <label for="minimum_downvote">Minimum Downvote:</label>
                <input type="number" id="minimum_downvote" name="minimum_downvote" min="0">
                <label for="maximum_downvote">Maximum Downvote:</label>
                <input type="number" id="maximum_downvote" name="maximum_downvote" min="0">
        
                <!-- User filter -->
                <label for="user_name">User Name:</label>
                <input type="text" id="user_name" name="user_name">
        
                <button type="submit">Apply Filters</button>
                <button type="button" onclick="clearFilters()">Clear Filters</button>
            </form>
        </div>
    </div>

    {{-- Posts--}}
    <div class="news">
        @include('partials.posts', ['posts' => $posts])
    </div>
    @include('partials.event')
    <script>
        var filterPostsApplyRoute  = @json(route('filter.posts.apply'));
    </script>
    <script src="{{ asset('js/create_post.js') }}"></script>
    <script src="{{ asset('js/filters.js') }}"></script>
@endsection