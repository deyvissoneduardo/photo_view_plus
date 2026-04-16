# Flutter Photo View

[![Tests status](https://img.shields.io/github/actions/workflow/status/bluefireteam/photo_view/ci.yml?branch=master)](https://github.com/bluefireteam/photo_view/actions)
[![Pub](https://img.shields.io/pub/v/photo_view.svg?style=popout)](https://pub.dartlang.org/packages/photo_view)

`photo_view` fornece um widget com zoom para imagens e conteúdo customizado,
sensível a gestos. Esta versão foi atualizada para Flutter moderno, fortalece a
tipagem da API e adiciona novos pontos de configuração para overlays, galeria e
políticas de interação.

## Requisitos

- Flutter `>=3.14.5`
- Dart `>=3.1.0`

```yaml
dependencies:
  photo_view: ^0.15.0
```

## Novidades

- baseline em Flutter 3.14.5+ e Dart 3.1+
- API de escala tipada com `PhotoViewScale.fixed(...)`
- novo `PhotoViewOptions` para consolidar a configuração do widget
- novo `PhotoViewGalleryOptions` para preload e retenção na galeria
- customização mais rica com `overlayBuilder`, `backgroundBuilder`,
  `loadingStateBuilder` e `errorStateBuilder`
- `PhotoViewInteractionPolicy` injetável para regras de clamp, retorno após
  gesto e ajuste dinâmico de `filterQuality`
- cache de `PhotoViewGalleryPageOptions` e preload configurável de imagens
- arquitetura interna organizada em `ui/`, `domain/`, `data/`, `core/` e
  `shared/`

## Uso Básico

```dart
import 'package:photo_view/photo_view.dart';

PhotoView(
  imageProvider: const AssetImage('assets/large-image.jpg'),
  initialScale: PhotoViewScale.contained,
  minScale: PhotoViewScale.contained * 0.8,
  maxScale: PhotoViewScale.covered * 1.8,
);
```

Para aplicar zoom em qualquer widget:

```dart
PhotoView.customChild(
  child: const FlutterLogo(size: 200),
  childSize: const Size(200, 200),
  initialScale: const PhotoViewScale.fixed(1),
);
```

## Configuração com `PhotoViewOptions`

Para código novo, prefira `options`. Os parâmetros legados do construtor ainda
funcionam e têm precedência quando usados junto com `options`.

```dart
PhotoView(
  imageProvider: const AssetImage('assets/large-image.jpg'),
  options: PhotoViewOptions(
    filterQuality: FilterQuality.high,
    strictScale: true,
    overlayBuilder: (context, details) => Align(
      alignment: Alignment.bottomRight,
      child: Text(details.scaleState.name),
    ),
  ),
);
```

`PhotoViewOptions` suporta:

- `backgroundDecoration`
- `wantKeepAlive`
- `customSize`
- `gestureDetectorBehavior`
- `tightMode`
- `filterQuality`
- `disableGestures`
- `enablePanAlways`
- `strictScale`
- `interactionPolicy`
- `overlayBuilder`
- `backgroundBuilder`
- `loadingStateBuilder`
- `errorStateBuilder`

## Galeria

```dart
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

PhotoViewGallery.builder(
  itemCount: galleryItems.length,
  options: const PhotoViewGalleryOptions(
    preloadPagesCount: 2,
    pageRetentionPolicy: PhotoViewGalleryPageRetentionPolicy.keepAlive,
  ),
  builder: (context, index) {
    final item = galleryItems[index];
    return PhotoViewGalleryPageOptions(
      imageProvider: AssetImage(item.image),
      initialScale: PhotoViewScale.contained,
      heroAttributes: PhotoViewHeroAttributes(tag: item.id),
      options: PhotoViewOptions(
        overlayBuilder: (_, details) => Align(
          alignment: Alignment.topRight,
          child: Text(details.scaleState.name),
        ),
      ),
    );
  },
);
```

`PhotoViewGalleryOptions` adiciona:

- `preloadPagesCount`
- `pageRetentionPolicy`
- `scrollPhysics`
- `scrollDirection`
- `allowImplicitScrolling`
- `pageSnapping`
- `options` compartilhado para todas as páginas

`PhotoViewGalleryPageOptions` agora também aceita:

- `pageKey`
- `options`

## Políticas de Interação

`PhotoViewInteractionPolicy` permite customizar o comportamento sem precisar
forkar o widget.

```dart
const policy = PhotoViewInteractionPolicy(
  filterQuality: defaultFilterQualityProvider,
  clampPosition: defaultClampPositionPolicy,
  onGestureEnd: defaultGestureEndPolicy,
);
```

Você pode substituir:

- a lógica de clamp da posição
- o comportamento de retorno/fling após o gesto
- a qualidade de filtro usada durante gestos ativos

## Guia de Migração

### 1. Atualize as constraints de SDK

Use Flutter `>=3.14.5` e Dart `>=3.1.0`.

### 2. Substitua escalas `dynamic`

Antes:

```dart
PhotoView(
  minScale: 0.8,
  maxScale: 3.0,
  initialScale: 1.0,
);
```

Agora:

```dart
PhotoView(
  minScale: const PhotoViewScale.fixed(0.8),
  maxScale: const PhotoViewScale.fixed(3.0),
  initialScale: const PhotoViewScale.fixed(1.0),
);
```

Escalas relativas ao viewport continuam funcionando:

```dart
PhotoView(
  minScale: PhotoViewComputedScale.contained * 0.8,
  maxScale: PhotoViewComputedScale.covered * 1.8,
  initialScale: PhotoViewScale.contained,
);
```

### 3. Mova flags opcionais para `options`

Antes:

```dart
PhotoView(
  imageProvider: provider,
  filterQuality: FilterQuality.high,
  strictScale: true,
  enablePanAlways: false,
);
```

Agora:

```dart
PhotoView(
  imageProvider: provider,
  options: const PhotoViewOptions(
    filterQuality: FilterQuality.high,
    strictScale: true,
    enablePanAlways: false,
  ),
);
```

### 4. Migre a configuração da galeria

Antes a retenção global dependia basicamente de `wantKeepAlive`.

Agora você pode usar:

```dart
const PhotoViewGalleryOptions(
  preloadPagesCount: 2,
  pageRetentionPolicy: PhotoViewGalleryPageRetentionPolicy.keepAlive,
)
```

### 5. Adote builders ricos para loading e erro

Antes:

```dart
loadingBuilder: (context, event) => const CircularProgressIndicator(),
errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
```

Agora:

```dart
options: PhotoViewOptions(
  loadingStateBuilder: (context, details) {
    return CircularProgressIndicator(
      value: details.progress == null
          ? null
          : details.progress!.cumulativeBytesLoaded /
              details.progress!.expectedTotalBytes!,
    );
  },
  errorStateBuilder: (context, details) => Text('${details.error}'),
),
```

### Resumo das Breaking Changes

- versões mínimas de Flutter e Dart foram elevadas
- entradas de escala agora são tipadas como `PhotoViewScale`
- os novos objetos `options` são o caminho preferido para configuração
- a galeria passou a ter preload e retenção explícitos

## Controllers

`PhotoViewController` expõe o estado do viewport.  
`PhotoViewScaleStateController` expõe as transições de estado de escala.

Ambos seguem o ciclo padrão de controllers no Flutter: crie externamente
quando precisar controlar o widget, escute os streams e faça `dispose` quando
não forem mais usados.

## Arquitetura Interna

Internamente o pacote está organizado em:

- `lib/src/ui/`: widgets, view models e coordinators
- `lib/src/domain/`: modelos imutáveis e regras de interação
- `lib/src/data/`: resolução de `ImageStream`
- `lib/src/core/`: renderização e layout de baixo nível
- `lib/src/shared/`: utilitários pequenos de fundação

Isso importa principalmente para contribuidores. Para uso do package, continue
consumindo as APIs exportadas por `lib/photo_view.dart` e
`lib/photo_view_gallery.dart`.

## Validação

O estado atual do pacote foi validado com:

- `flutter analyze`
- `flutter test`

## Example App

Para rodar o exemplo:

```bash
flutter run -d <device> example/lib/main.dart
```

O exemplo de galeria já demonstra preload, retenção de página e overlays.
