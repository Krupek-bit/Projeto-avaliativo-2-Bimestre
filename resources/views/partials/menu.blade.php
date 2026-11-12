<nav class="navbar navbar-expand-lg navbar-dark bg-dark px-3">
  <a class="navbar-brand" href="/">Gestão de Frota</a>
  <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#menuPrincipal">
    <span class="navbar-toggler-icon"></span>
  </button>
  <div class="collapse navbar-collapse" id="menuPrincipal">
    <ul class="navbar-nav">
      <li class="nav-item"><a class="nav-link" href="{{ route('veiculos.index') }}">Veículos</a></li>
      <li class="nav-item"><a class="nav-link" href="{{ route('motoristas.index') }}">Motoristas</a></li>
      <li class="nav-item"><a class="nav-link" href="{{ route('viagens.index') }}">Viagens</a></li>
      <li class="nav-item"><a class="nav-link" href="{{ route('abastecimentos.index') }}">Abastecimentos</a></li>
      <li class="nav-item"><a class="nav-link" href="{{ route('manutencoes.index') }}">Manutenções</a></li>
      <li class="nav-item"><a class="nav-link" href="{{ route('despesas.index') }}">Despesas</a></li>
      <li class="nav-item"><a class="nav-link" href="{{ route('hodometros.index') }}">Hodômetros</a></li>
      <li class="nav-item"><a class="nav-link" href="#">Histórico</a></li>
    </ul>
  </div>
</nav>
