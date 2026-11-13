<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Entrar - Gestão de Frota</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <style>
    body { background: linear-gradient(135deg, #283593 0%, #1a237e 65%, #ec407a 150%); }
    .login-card { max-width: 420px; width: 100%; }
    .btn-login { background-color: #283593; border-color: #283593; color: #fff; }
    .btn-login:hover { background-color: #1a237e; border-color: #1a237e; color: #fff; }
  </style>
</head>
<body class="min-vh-100 d-flex align-items-center justify-content-center p-3">
  <div class="card shadow login-card">
    <div class="card-body p-4 p-md-5">
      <div class="text-center mb-4">
        <h1 class="h3 mb-1">Gestão de Frota</h1>
        <p class="text-muted mb-0">Acesse sua conta para continuar</p>
      </div>

      <form method="POST" action="{{ route('login.attempt') }}">
        @csrf
        <div class="mb-3">
          <label for="email" class="form-label">E-mail</label>
          <input type="email" id="email" name="email" value="{{ old('email') }}" required autofocus
                 class="form-control @error('email') is-invalid @enderror">
          @error('email') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>

        <div class="mb-4">
          <label for="password" class="form-label">Senha</label>
          <input type="password" id="password" name="password" required
                 class="form-control @error('password') is-invalid @enderror">
          @error('password') <div class="invalid-feedback">{{ $message }}</div> @enderror
        </div>

        <button type="submit" class="btn btn-login w-100">Entrar</button>
      </form>
    </div>
  </div>
</body>
</html>