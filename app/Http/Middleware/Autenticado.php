<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class Autenticado
{
    public function handle(Request $request, Closure $next): Response
    {
        if (! $request->session()->get('autenticado')) {
            return redirect()->guest(route('login'));
        }

        return $next($request);
    }
}