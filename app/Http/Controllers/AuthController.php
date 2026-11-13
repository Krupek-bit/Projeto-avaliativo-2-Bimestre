<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function showLogin(Request $request)
    {
        if ($request->session()->get('autenticado')) {
            return redirect()->route('home');
        }

        return view('auth.login');
    }

    public function login(Request $request)
    {
        $dados = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
        ]);

        $usuario = config('frota.usuario');

        $emailOk = hash_equals(strtolower($usuario['email']), strtolower($dados['email']));
        $senhaOk = hash_equals($usuario['senha'], $dados['password']);

        if ($emailOk && $senhaOk) {
            $request->session()->regenerate();
            $request->session()->put([
                'autenticado' => true,
                'usuario_nome' => $usuario['nome'],
            ]);

            return redirect()->intended(route('home'));
        }

        return back()
            ->withErrors(['email' => 'E-mail ou senha inválidos.'])
            ->onlyInput('email');
    }

    public function logout(Request $request)
    {
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('login');
    }
}