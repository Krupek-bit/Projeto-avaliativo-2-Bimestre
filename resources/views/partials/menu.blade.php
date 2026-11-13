<nav class="navbar navbar-expand-lg navbar-dark bg-dark px-3">
  <a class="navbar-brand" href="{{ route('home') }}">Gestão de Frota</a>
  <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#menuPrincipal">
    <span class="navbar-toggler-icon"></span>
  </button>
  <div class="collapse navbar-collapse" id="menuPrincipal">
    <ul class="navbar-nav me-auto">
      <li class="nav-item"><a class="nav-link {{ request()->routeIs('home') ? 'active' : '' }}" href="{{ route('home') }}">Início</a></li>
      <li class="nav-item"><a class="nav-link {{ request()->routeIs('veiculos.*') ? 'active' : '' }}" href="{{ route('veiculos.index') }}">Veículos</a></li>
      <li class="nav-item"><a class="nav-link {{ request()->routeIs('motoristas.*') ? 'active' : '' }}" href="{{ route('motoristas.index') }}">Motoristas</a></li>
      <li class="nav-item"><a class="nav-link {{ request()->routeIs('viagens.*') ? 'active' : '' }}" href="{{ route('viagens.index') }}">Viagens</a></li>
      <li class="nav-item"><a class="nav-link {{ request()->routeIs('abastecimentos.*') ? 'active' : '' }}" href="{{ route('abastecimentos.index') }}">Abastecimentos</a></li>
      <li class="nav-item"><a class="nav-link {{ request()->routeIs('manutencoes.*') ? 'active' : '' }}" href="{{ route('manutencoes.index') }}">Manutenções</a></li>
      <li class="nav-item"><a class="nav-link {{ request()->routeIs('despesas.*') ? 'active' : '' }}" href="{{ route('despesas.index') }}">Despesas</a></li>
      <li class="nav-item"><a class="nav-link {{ request()->routeIs('hodometros.*') ? 'active' : '' }}" href="{{ route('hodometros.index') }}">Hodômetros</a></li>
    </ul>

    <div class="d-flex align-items-center gap-2 mt-2 mt-lg-0">
      <span class="text-white-50 small">{{ session('usuario_nome') }}</span>
      <form method="POST" action="{{ route('logout') }}">
        @csrf
        <button class="btn btn-sm btn-outline-light">Sair</button>
      </form>
    </div>
  </div>
</nav>