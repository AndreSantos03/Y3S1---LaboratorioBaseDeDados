<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">

        <!-- CSRF Token -->
        <meta name="csrf-token" content="{{ csrf_token() }}">

        <title>@yield('title')</title>

        <!-- Styles -->
        <link href="{{ url('css/milligram.min.css') }}" rel="stylesheet">
        <link href="{{ url('css/app.css') }}" rel="stylesheet">
        <script type="text/javascript">
            // Fix for Firefox autofocus CSS bug
            // See: http://stackoverflow.com/questions/18943276/html-5-autofocus-messes-up-css-loading/18945951#18945951
        </script>
        <script type="text/javascript" src={{ url('js/app.js') }} defer>
        </script>
    </head>
    <body>
        <header>
            <h3>SWC News</h3>
            <hr>
        </header>
        <main>
            <h1>@yield('header')</h1>
            <nav>
                <a href="{{ route('welcome') }}">News Feed</a>
                <br>
                <a href="{{ route('user_news') }}">User News</a>
                <br>
                <a href="{{ route('profile') }}">Profile</a>
            </nav>
            <br>
            <div id="content">
                @yield('content')
            </div>
        </main>
        <footer>
            <hr/>
            © SWC News
        </footer>
    </body>
</html>