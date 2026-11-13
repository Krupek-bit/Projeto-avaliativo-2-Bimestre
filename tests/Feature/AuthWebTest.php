<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthWebTest extends TestCase
{
    use RefreshDatabase;

    public function test_tela_de_login_e_exibida(): void
    {
        $this->get('/login')
            ->assertOk()
            ->assertSee('Entrar');
    }

    public function test_visitante_e_redirecionado_para_o_login(): void
    {
        $this->get('/')->assertRedirect('/login');
    }

    public function test_login_com_credenciais_validas_abre_o_menu_inicial(): void
    {
        config(['frota.usuario' => [
            'nome' => 'Administrador',
            'email' => 'admin@frota.com',
            'senha' => 'admin123',
        ]]);

        $this->post('/login', ['email' => 'admin@frota.com', 'password' => 'admin123'])
            ->assertRedirect('/');

        $this->get('/')
            ->assertOk()
            ->assertSee('Módulos');
    }

    public function test_login_com_senha_errada_mostra_erro(): void
    {
        $this->post('/login', ['email' => 'admin@frota.com', 'password' => 'errada'])
            ->assertSessionHasErrors('email');
    }
}